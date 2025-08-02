//*********************************************************
//
// Copyright (c) Microsoft. All rights reserved.
// This code is licensed under the MIT License (MIT).
// THIS CODE IS PROVIDED *AS IS* WITHOUT WARRANTY OF
// ANY KIND, EITHER EXPRESS OR IMPLIED, INCLUDING ANY
// IMPLIED WARRANTIES OF FITNESS FOR A PARTICULAR
// PURPOSE, MERCHANTABILITY, OR NON-INFRINGEMENT.
//
//*********************************************************

#ifndef RAYTRACING_HLSL
#define RAYTRACING_HLSL

#define HLSL
#include "RaytracingHlslCompat.h"
struct Ellipsoid
{
    float3 center;
    float3 radii; //<= 1
    float4 quat;
    matrix rot;
    float extent; //scale factor
};
struct KernelPrimitive
{
    float sigma; //primitive cross section [m^2]
    float3 albedo;
};

struct EllipsoidAttr
{
    float3 normal;
    float tIn;
    float tOut;
};
struct Intersection
{
    uint pIndex; //primitive index
    float tIn;
    float tOut;
};


RaytracingAccelerationStructure Scene : register(t0, space0);
RWTexture2D<float4> RenderTarget : register(u0);
ByteAddressBuffer Indices : register(t1, space0);
StructuredBuffer<Vertex> Vertices : register(t2, space0);
StructuredBuffer<Ellipsoid> Ellipsoids: register(t3, space0);
StructuredBuffer<KernelPrimitive> Kernels: register(t4, space0);

ConstantBuffer<SceneConstantBuffer> g_sceneCB : register(b0);
ConstantBuffer<CubeConstantBuffer> g_cubeCB : register(b1);

typedef BuiltInTriangleIntersectionAttributes MyAttributes;
struct RayPayload
{
    Intersection intersection;
    bool hasHit;
};

// Generate a ray in world space for a camera pixel corresponding to an index from the dispatched 2D grid.
inline void GenerateCameraRay(uint2 index, out float3 origin, out float3 direction)
{
    float2 xy = index + 0.5f; // center in the middle of the pixel.
    float2 screenPos = xy / DispatchRaysDimensions().xy * 2.0 - 1.0;

    // Invert Y for DirectX-style coordinates.
    screenPos.y = -screenPos.y;

    // Unproject the pixel coordinate into a ray.
    float4 world = mul(float4(screenPos, 0, 1), g_sceneCB.projectionToWorld);

    world.xyz /= world.w;
    origin = g_sceneCB.cameraPosition.xyz;
    direction = normalize(world.xyz - origin);
}

// Diffuse lighting calculation.
float4 CalculateDiffuseLighting(float3 hitPosition, float3 normal)
{
    float3 pixelToLight = normalize(g_sceneCB.lightPosition.xyz - hitPosition);

    // Diffuse contribution.
    float fNDotL = max(0.0f, dot(pixelToLight, normal));

    return g_cubeCB.albedo * g_sceneCB.lightDiffuseColor * fNDotL;
}
float CalculateTransmittance(float3 r0, float3 rd, Intersection intersection)
{
    float3 p = r0 + intersection.tIn * rd;
    float3 p1 = r0 + intersection.tOut * rd;
    
    //convert points to local space
    Ellipsoid e = Ellipsoids[intersection.pIndex];
    p = mul((float3x3) transpose(e.rot), p - e.center);
    p1 = mul((float3x3) transpose(e.rot), p1 - e.center);
    
    float3 s = e.radii * e.extent;
    
    float3 w = p1 - p;
    float t = sqrt(dot(w, w)); //magnitude
    w /= t; //normalized direction
        
    float wx2 = w.x * w.x;
    float wy2 = w.y * w.y;
    float wz2 = w.z * w.z;
    
    float px2 = p.x * p.x;
    float py2 = p.y * p.y;
    float pz2 = p.z * p.z;
    
    float sx2 = s.x * s.x;
    float sy2 = s.y * s.y;
    float sz2 = s.z * s.z;
    
    float K1 = 3 * (((px2 - sx2) * sy2 + py2 * sx2) * sz2 + pz2 * sx2 * sy2);
    float K2 = 3 * (p.z * sx2 * sy2 * w.z + p.y * sx2 * sz2 * w.y + p.x * sy2 * sz2 * w.x);
    float K3 = sx2 * sy2 * wz2 + sx2 * sz2 * wy2 + sy2 * sz2 * wx2;
    float Knorm = 5.0 / (8.0 * 3.141592f * s.x * sx2 * s.y * sy2 * s.z * sz2);
    
    float density = -Knorm * (K1 * t + K2 * t * t + K3 * t * t * t);
    
    float normFactor = 5.0 / (2.0 * 3.141592f * sqrt((sx2 * sy2 + sx2 * sz2 + sy2 * sz2) / 3.0));
    density /= normFactor;
    //float density = sqrt(dot(deltaP, deltaP)) * (P1.x + P1.y + P1.z + 0.5f * (deltaP.x + deltaP.y + deltaP.z)); //for f(x,y,z) = x+y+z
    //float density = sqrt(dot(w, w)) * (P1.y + 0.5f * w.y); //for f(x,y,z) = y
    //float density = sqrt(dot(deltaP, deltaP)) * ((P2.y >= 0) ? 1 : -1) * (P2.y + 0.5f * deltaP.y); //for f(x,y,z) = |y|
    
    return exp(-density * Kernels[intersection.pIndex].sigma); //transmittance
}


[shader("raygeneration")]
void MyRaygenShader()
{
    float3 rayDir;
    float3 origin;
    float4 background = float4(0.0f, 0.2f, 0.4f, 1.0f);
    
    // Generate a ray for a camera pixel corresponding to an index from the dispatched 2D grid.
    GenerateCameraRay(DispatchRaysIndex().xy, origin, rayDir);

    // Trace the ray.
    // Set the ray's extents.
    RayDesc ray;
    ray.Origin = origin;
    ray.Direction = rayDir;
    // Set TMin to a non-zero small value to avoid aliasing issues due to floating - point errors.
    // TMin should be kept small to prevent missing geometry at close contact areas.
    ray.TMin = 0.0001;
    ray.TMax = 10000.0;
    Intersection intersection;
    RayPayload payload = { intersection, true};
    
    float tr = 1; 
    uint pIndex = 0;
    float tIn = 0;
    float tOut = 0;
    float3 volColor = float3(0, 0, 0);
    while (payload.hasHit)
    {
        payload.hasHit = false;
        TraceRay(Scene, RAY_FLAG_CULL_BACK_FACING_TRIANGLES, ~0, 0, 1, 0, ray, payload);
        if (payload.hasHit)
        {
            //pIndex = payload.intersection.pIndex;
            //tIn = payload.intersection.tIn;
            //tOut = payload.intersection.tOut;
            float tri = CalculateTransmittance(ray.Origin, ray.Direction, payload.intersection);
            volColor += Kernels[payload.intersection.pIndex].albedo * (1-tri);
            tr *= tri;
            ray.Origin = ray.Origin + rayDir * payload.intersection.tIn;
        }   
    }
    float3 color = volColor * (1-tr) + background.rgb * tr;
    // Write the raytraced color to the output texture.
    RenderTarget[DispatchRaysIndex().xy] = float4(color, 1);
}

[shader("miss")]
void MyMissShader(inout RayPayload payload)
{
    //float4 background = float4(0.0f, 0.2f, 0.4f, 1.0f);
    //payload.color = background;
    payload.hasHit = false;
}

[shader("intersection")]
void EllipsoidIntersectionShader()
{
    uint ellipsoidIndex = PrimitiveIndex();
    Ellipsoid s = Ellipsoids[ellipsoidIndex];
    //Given ray: r0 + t*rd, substitute as (x,y,z) in ellipsoid equation: x^2/rx^2 + y^2/ry^2 + z^2/rz^2 = 1 (rx,ry,rz = ellipsoid radii)
    float3 r0 = mul((float3x3)transpose(s.rot), WorldRayOrigin() - s.center);
    float3 rd = mul((float3x3)transpose(s.rot), WorldRayDirection());
    
    float3 scale = s.radii * s.extent;
    
    float3 rdN = rd / scale;
    float3 r0N = r0 / scale;
    
    float a = dot(rdN, rdN);
    float b = 2 * dot(r0N, rdN);
    float c = dot(r0N, r0N) - 1.0f;   
   
    EllipsoidAttr attr;
    uint hitKind = 0; //user defined
    
    float discriminant = b * b - 4.0f * a * c;
    if (discriminant < 0.0f)
        return;

    float sqrtDisc = sqrt(discriminant);
    float t0 = (-b - sqrtDisc) / (2.0f * a);
    float t1 = (-b + sqrtDisc) / (2.0f * a);

    if (t0 < RayTMin()) //prevents intersection from ray generated inside the ellipsoid
        return;
    
    float t = (t0 > 0) ? t0 : t1;
    attr.tIn = t0;
    attr.tOut = t1;
    
    //if (ellipsoidIndex == 2)
    float3 pos = WorldRayOrigin() + t * WorldRayDirection();
    attr.normal = /*normalize(pos - s.center);*/normalize(2 * (pos / (s.radii * s.radii))); //gradient function of x^2/rx^2 + y^2/ry^2 + z^2/rz^2 - 1 = 0
    ReportHit(t, hitKind, attr);    
}

[shader("closesthit")]
void EllipsoidClosestHitShader(inout RayPayload payload, in EllipsoidAttr attr)
{
    payload.hasHit = true;
    payload.intersection.tIn = attr.tIn;
    payload.intersection.tOut = attr.tOut;
    payload.intersection.pIndex = PrimitiveIndex();
}

#endif // RAYTRACING_HLSL