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
#define pi 3.141592f

struct Ellipsoid
{
    float3 center;
    float3 radii; //<= 1
    matrix rot;
    float extent; //scale factor
};
struct KernelPrimitive
{
    float sigma; //primitive extinction coefficient
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
//https://gpuopen.com/download/Accurate_Diffuse_Lighting_from_Spherical_Gaussian_Lights_(supplemental).pdf
float erf(float x)
{
    // Early return for large |x|.
    if (abs(x) >= 4.0)
        return asfloat((asuint(x) & 0x80000000) ^ asuint(1.0)); //bitwise AND and XOR operators
    
    // Polynomial approximation based on https://forums.developer.nvidia.com/t/optimized-version-of-single-precision-error-function-erff/40977
    if (abs(x) > 1.0)
    {
        float A1 = 1.628459513;
        float A2 = 9.15674746e-1;
        float A3 = 1.54329389e-1;
        float A4 = -3.51759829e-2;
        float A5 = 5.66795561e-3;
        float A6 = -5.64874616e-4;
        float A7 = 2.58907676e-5;
        float a = abs(x);
        float y = 1.0 - exp2(-(((((((A7 * a + A6) * a + A5) * a + A4) * a + A3) * a + A2) * a + A1) * a));
        return asfloat((asuint(x) & 0x80000000) ^ asuint(y));
    }
    else
    {
        float A1 = 1.128379121;
        float A2 = -3.76123011e-1;
        float A3 = 1.12799220e-1;
        float A4 = -2.67030653e-2;
        float A5 = 4.90735564e-3;
        float A6 = -5.58853149e-4;
        float x2 = x * x;
        return (((((A6 * x2 + A5) * x2 + A4) * x2 + A3) * x2 + A2) * x2 + A1) * x;
    }
}

float ComputeDensityIntegral(float3 p, float3 p1, float3 s, float3 w, float t, bool normalized, bool isGaussian, float tmax, float extent)
{
    float wx2 = w.x * w.x;
    float wy2 = w.y * w.y;
    float wz2 = w.z * w.z;
    
    float px2 = p.x * p.x;
    float py2 = p.y * p.y;
    float pz2 = p.z * p.z;
    
    if (!isGaussian)
        s *= extent;
    float sx2 = s.x * s.x;
    float sy2 = s.y * s.y;
    float sz2 = s.z * s.z;
    
    float density = 0.0f;
    float normFactor = 1.0f;
    if (!isGaussian) //epanechnikov
    {                
        float K1 = 3 * (((px2 - sx2) * sy2 + py2 * sx2) * sz2 + pz2 * sx2 * sy2);
        float K2 = 3 * (p.z * sx2 * sy2 * w.z + p.y * sx2 * sz2 * w.y + p.x * sy2 * sz2 * w.x);
        float K3 = sx2 * sy2 * wz2 + sx2 * sz2 * wy2 + sy2 * sz2 * wx2;
        float Knorm = 5.0f / (8.0f * pi * s.x * sx2 * s.y * sy2 * s.z * sz2);
    
        density = -Knorm * (K1 * t + K2 * t * t + K3 * t * t * t);       
        if (normalized) normFactor = 5.0f / (2.0f * pi * sqrt((sx2 * sy2 + sx2 * sz2 + sy2 * sz2) / 3.0f));
    }
    else //gaussian
    {
        float C0 = sx2 * sy2 * wz2 + sx2 * sz2 * wy2 + sy2 * sz2 * wx2;

        float C1 = (px2 * sy2 * wz2 + py2 * sx2 * wz2 //C3
        - 2 * p.y * p.z * sx2 * w.y * w.z //C3
        - 2 * p.x * p.z * sy2 * w.x * w.z //C3
        + px2 * sz2 * wy2 + pz2 * sx2 * wy2 //C4
        - 2 * p.x * p.y * sz2 * w.x * w.y  //C4
        + py2 * sz2 * wx2 + pz2 * sy2 * wx2); //C4

        C1 /= (2.0f * C0);
        
        float denom = 4.0f * pi * sqrt(C0);
        
        density = exp(-C1) * rcp(denom);

        float C2 = p.z * sx2 * sy2 * w.z + p.y * sx2 * sz2 * w.y + p.x * sy2 * sz2 * w.x;
        float erf_denom = s.x * s.y * s.z * sqrt(2.0f * C0);

        float erf1 = erf((tmax * C0 + C2) / erf_denom);
        float erf2 = erf(C2 / erf_denom);

        density *= (erf1 - erf2);
        
        if (normalized) normFactor = rcp(0.5f * 4.0f * pi * sqrt((sx2 * sy2 + sx2 * sz2 + sy2 * sz2) / 3.0f));
    }
    
    if (normalized) density /= normFactor;
    density = max(density, 0.0f);
    return density;
}
float CalculateTransmittance(float3 r0, float3 rd, Intersection intersection)
{
    float3 p = r0 + intersection.tIn * rd;
    float3 p1 = r0 + intersection.tOut * rd;
    
    //convert points to local space
    Ellipsoid e = Ellipsoids[intersection.pIndex];
    p = mul((float3x3) transpose(e.rot), p - e.center);
    p1 = mul((float3x3) transpose(e.rot), p1 - e.center);
    
    float3 s = e.radii;
    
    float3 w = p1 - p;
    float deltaT = sqrt(dot(w, w)); //magnitude
    w /= deltaT; //normalized direction
    
    //NOTE: the w value of cameraPosition determines if Gaussian kernels will be used
    float density = ComputeDensityIntegral(p, p1, s, w, deltaT, false, g_sceneCB.cameraPosition.w, intersection.tOut, e.extent);
    
    return exp(-density * Kernels[intersection.pIndex].sigma); //transmittance
}


[shader("raygeneration")]
void MyRaygenShader()
{
    float3 rayDir;
    float3 origin;
    float4 background = float4(1, 1, 1, 1);
    //float4(0.0f, 0.2f, 0.4f, 1.0f);
    
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
    
    float trAcc = 1; 
    float3 volColor = float3(0, 0, 0);
    while (payload.hasHit)
    {
        TraceRay(Scene, RAY_FLAG_CULL_BACK_FACING_TRIANGLES, ~0, 0, 1, 0, ray, payload);
        if (payload.hasHit)
        {
            float tri = CalculateTransmittance(ray.Origin, ray.Direction, payload.intersection);
            trAcc *= tri;
            volColor += Kernels[payload.intersection.pIndex].albedo * (1 - tri); //when volume is purely absorptive albedo = (0,0,0)
            ray.Origin = ray.Origin + rayDir * payload.intersection.tIn; //next ray will originate from closest intersection point, effectively ignoring previous closest primitive 
        }   
    }
    float3 color = volColor * (1 - trAcc) + background.rgb * trAcc; //blends volume color and background depending on accumulated volume transmittance along ray
    // Write the raytraced color to the output texture.
    RenderTarget[DispatchRaysIndex().xy] = float4(color, 1);
}

[shader("miss")]
void MyMissShader(inout RayPayload payload)
{
    payload.hasHit = false;
}

[shader("intersection")]
void EllipsoidIntersectionShader()
{
    uint ellipsoidIndex = PrimitiveIndex();
    Ellipsoid s = Ellipsoids[ellipsoidIndex];
    //Convert ray origin and direction into ellipsoid local space
    float3 r0 = mul((float3x3)transpose(s.rot), WorldRayOrigin() - s.center);
    float3 rd = mul((float3x3)transpose(s.rot), WorldRayDirection());
    
    float3 scale = s.radii * s.extent;
    
    float3 rdN = rd / scale;
    float3 r0N = r0 / scale;
    
    //Given ray: r0 + t*rd, substitute as (x,y,z) in ellipsoid equation: x^2/rx^2 + y^2/ry^2 + z^2/rz^2 = 1 (rx,ry,rz = ellipsoid radii)
    //Result is quadratic equation at^2 + tx + c = 0
    float a = dot(rdN, rdN);
    float b = 2 * dot(r0N, rdN);
    float c = dot(r0N, r0N) - 1.0f;   
   
    EllipsoidAttr attr;
    uint hitKind = 0; //user defined
    
    float discriminant = b * b - 4.0f * a * c;
    if (discriminant < 0.0f) //no real solution -> no intersection
        return;

    //solving the quadratic equation:
    float sqrtDisc = sqrt(discriminant);
    float t0 = (-b - sqrtDisc) / (2.0f * a);
    float t1 = (-b + sqrtDisc) / (2.0f * a);

    if (t0 <= 0) //prevents intersection from ray generated inside the ellipsoid
        return;
    
    attr.tIn = t0;
    attr.tOut = t1;
    ReportHit(t0, hitKind, attr);    
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
