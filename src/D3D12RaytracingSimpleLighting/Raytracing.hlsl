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
    float albedo;
};

struct EllipsoidAttr
{
    float3 normal;
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

// Load three 16 bit indices from a byte addressed buffer.
uint3 Load3x16BitIndices(uint offsetBytes)
{
    uint3 indices;

    // ByteAdressBuffer loads must be aligned at a 4 byte boundary.
    // Since we need to read three 16 bit indices: { 0, 1, 2 } 
    // aligned at a 4 byte boundary as: { 0 1 } { 2 0 } { 1 2 } { 0 1 } ...
    // we will load 8 bytes (~ 4 indices { a b | c d }) to handle two possible index triplet layouts,
    // based on first index's offsetBytes being aligned at the 4 byte boundary or not:
    //  Aligned:     { 0 1 | 2 - }
    //  Not aligned: { - 0 | 1 2 }
    const uint dwordAlignedOffset = offsetBytes & ~3;    
    const uint2 four16BitIndices = Indices.Load2(dwordAlignedOffset);
 
    // Aligned: { 0 1 | 2 - } => retrieve first three 16bit indices
    if (dwordAlignedOffset == offsetBytes)
    {
        indices.x = four16BitIndices.x & 0xffff;
        indices.y = (four16BitIndices.x >> 16) & 0xffff;
        indices.z = four16BitIndices.y & 0xffff;
    }
    else // Not aligned: { - 0 | 1 2 } => retrieve last three 16bit indices
    {
        indices.x = (four16BitIndices.x >> 16) & 0xffff;
        indices.y = four16BitIndices.y & 0xffff;
        indices.z = (four16BitIndices.y >> 16) & 0xffff;
    }

    return indices;
}

typedef BuiltInTriangleIntersectionAttributes MyAttributes;
struct RayPayload
{
    float4 color;
};

// Retrieve hit world position.
float3 HitWorldPosition() { return WorldRayOrigin() + RayTCurrent() * WorldRayDirection(); }

// Retrieve attribute at a hit position interpolated from vertex attributes using the hit's barycentrics.
float3 HitAttribute(float3 vertexAttribute[3], BuiltInTriangleIntersectionAttributes attr)
{
    return vertexAttribute[0] +
        attr.barycentrics.x * (vertexAttribute[1] - vertexAttribute[0]) +
        attr.barycentrics.y * (vertexAttribute[2] - vertexAttribute[0]);
}

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

[shader("raygeneration")]
void MyRaygenShader()
{
    float3 rayDir;
    float3 origin;
    
    // Generate a ray for a camera pixel corresponding to an index from the dispatched 2D grid.
    GenerateCameraRay(DispatchRaysIndex().xy, origin, rayDir);

    // Trace the ray.
    // Set the ray's extents.
    RayDesc ray;
    ray.Origin = origin;
    ray.Direction = rayDir;
    // Set TMin to a non-zero small value to avoid aliasing issues due to floating - point errors.
    // TMin should be kept small to prevent missing geometry at close contact areas.
    ray.TMin = 0.001;
    ray.TMax = 10000.0;
    RayPayload payload = { float4(0, 0, 0, 0) };
    TraceRay(Scene, RAY_FLAG_CULL_BACK_FACING_TRIANGLES, ~0, 0, 1, 0, ray, payload);

    // Write the raytraced color to the output texture.
    RenderTarget[DispatchRaysIndex().xy] = payload.color;
}

[shader("miss")]
void MyMissShader(inout RayPayload payload)
{
    float4 background = float4(0.0f, 0.2f, 0.4f, 1.0f);
    payload.color = background;
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
    {
        attr.normal = float3(0, 0, 0);
        ReportHit(1, hitKind, attr); //debug: shows AABB
        return;
    }

    float sqrtDisc = sqrt(discriminant);
    float t0 = (-b - sqrtDisc) / (2.0f * a);
    float t1 = (-b + sqrtDisc) / (2.0f * a);

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
    if (attr.normal.x == 0)
    {
        payload.color = float4(1, 1, 1, 1);
        return;
    }
   
    //payload.color = float4(PrimitiveIndex() == 0, PrimitiveIndex() == 1, 0, 1);

    float3 p = WorldRayOrigin() + attr.tIn * WorldRayDirection();
    float3 p2 = WorldRayOrigin() + attr.tOut * WorldRayDirection();
    
    //convert points to local space
    Ellipsoid e = Ellipsoids[PrimitiveIndex()];
    float3 s = e.radii;
    float3 scale = s * e.extent;
    p = mul((float3x3)transpose(e.rot), p - e.center)/* / scale*/;
    p2 = mul((float3x3)transpose(e.rot), p2 - e.center)/* / scale*/;
    
    float3 w = p2 - p;
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
    
    float K1 = 3 * (((px2 - sx2)*sy2 + py2*sx2) * sz2 + pz2 * sx2 * sy2);
    float K2 = 3 * (p.z*sx2*sy2*w.z + p.y*sx2*sz2*w.y + p.x*sy2*sz2*w.x);
    float K3 = sx2*sy2*wz2 + sx2*sz2*wy2 + sy2*sz2*wx2;
    float Knorm = 5.0 / (8.0 * 3.141592f * s.x * sx2 * s.y * sy2 * s.z * sz2); //15 / (168 * 3.141592f * sqrt(7*7*7) * sx2 * sy2 * sz2);
    
    float acc = -Knorm * (K1 * t + K2 * t * t + K3 * t * t * t);
    
    float normFactor = 5.0 / (2.0 * 3.141592f * sqrt((sx2 * sy2 + sx2 * sz2 + sy2 * sz2) / 3.0));
    //float acc = sqrt(dot(deltaP, deltaP)) * (P1.x + P1.y + P1.z + 0.5f * (deltaP.x + deltaP.y + deltaP.z)); //for f(x,y,z) = x+y+z
    //float acc = sqrt(dot(w, w)) * (P1.y + 0.5f * w.y); //for f(x,y,z) = y
    //float acc = sqrt(dot(deltaP, deltaP)) * ((P2.y >= 0) ? 1 : -1) * (P2.y + 0.5f * deltaP.y); //for f(x,y,z) = |y|
    acc /= normFactor;
    
    
    
    float3 color = float3(1, 1, 1) * /*(attr.tOut - attr.tIn)*/acc /** Kernels[PrimitiveIndex()].sigma*/;
    payload.color = float4(color, 1); //float4((attr.normal+1)*0.5f, 1); //color;
}

#endif // RAYTRACING_HLSL