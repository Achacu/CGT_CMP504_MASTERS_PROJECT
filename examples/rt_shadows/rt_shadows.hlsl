/*
* Copyright (c) 2014-2021, NVIDIA CORPORATION. All rights reserved.
*
* Permission is hereby granted, free of charge, to any person obtaining a
* copy of this software and associated documentation files (the "Software"),
* to deal in the Software without restriction, including without limitation
* the rights to use, copy, modify, merge, publish, distribute, sublicense,
* and/or sell copies of the Software, and to permit persons to whom the
* Software is furnished to do so, subject to the following conditions:
*
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL
* THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
* FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
* DEALINGS IN THE SOFTWARE.
*/

#pragma pack_matrix(row_major)

#include <donut/shaders/gbuffer.hlsli>
#include <donut/shaders/lighting.hlsli>
#include "donut/shaders/surface.hlsli"
#include "lighting_cb.h"

// ---[ Structures ]---

struct HitInfo
{
    bool missed;
};

// ---[ Resources ]---

ConstantBuffer<LightingConstants> g_Lighting : register(b0); //ambient color, light constants (direction, type...), view constants (matrices, viewport info...)

RWTexture2D<float4> u_Output : register(u0);

RaytracingAccelerationStructure SceneBVH : register(t0);
Texture2D t_GBufferDepth : register(t1);

//each of the textures will be indexed by pixel position and return a float4
Texture2D t_GBuffer0 : register(t2); //[albedo.rgb, opacity]
Texture2D t_GBuffer1 : register(t3); //[specular.rgb, occlusion]
Texture2D t_GBuffer2 : register(t4); //[normal.xyz, roughness]
Texture2D t_GBuffer3 : register(t5); //[emissive.rgb, nothing]


// ---[ Ray Generation Shader ]---

[shader("raygeneration")]
void RayGen()
{
    uint2 globalIdx = DispatchRaysIndex().xy;
    float2 pixelPosition = float2(globalIdx) + 0.5;
    
    //(gbuffer.hlsli)
    MaterialSample surfaceMaterial = DefaultMaterialSample();
    surfaceMaterial.diffuseAlbedo = float3(1, 1, 1);
    surfaceMaterial.opacity = 1;
    surfaceMaterial.specularF0 = 0;
    surfaceMaterial.occlusion = 0;
    surfaceMaterial.shadingNormal = float3(pixelPosition.x, pixelPosition.y, 0);
    surfaceMaterial.roughness = 1;
    surfaceMaterial.emissiveColor = 0;
    surfaceMaterial.geometryNormal = surfaceMaterial.shadingNormal;
    
    //MaterialSample surfaceMaterial = DecodeGBuffer(globalIdx, t_GBuffer0, t_GBuffer1, t_GBuffer2, t_GBuffer3);

    //calculates ray origin world position (gbuffer.hlsli)
    float3 surfaceWorldPos = ReconstructWorldPosition(g_Lighting.view, pixelPosition.xy, 0/*, t_GBufferDepth[pixelPosition.xy].x*/); //IMPORTANT
    
    //(gbuffer.hlsli)
    float3 viewIncident = GetIncidentVector(g_Lighting.view.cameraDirectionOrPosition, surfaceWorldPos);

    // Setup the ray
    RayDesc ray;
    ray.Origin = surfaceWorldPos;
    ray.Direction = -normalize(g_Lighting.light.direction);
    ray.TMin = 0.01f;
    ray.TMax = 100.f;

    // Trace the ray
    HitInfo payload;
    payload.missed = false;

    TraceRay(
        SceneBVH,
        RAY_FLAG_CULL_BACK_FACING_TRIANGLES,
        0xFF,
        0,
        0,
        0,
        ray,
        payload);

    float3 diffuseTerm = 0;
    float3 specularTerm = 0;

    float3 diffuseRadiance, specularRadiance;
    //(lighting.hlsli)
    ShadeSurface(g_Lighting.light, surfaceMaterial, surfaceWorldPos, viewIncident, diffuseRadiance, specularRadiance);
    //diffuseRadiance = 0;
    //specularRadiance = 0;
        
    diffuseTerm += (diffuseRadiance) * g_Lighting.light.color;
    specularTerm += (specularRadiance) * g_Lighting.light.color;

    diffuseTerm += g_Lighting.ambientColor.rgb * surfaceMaterial.diffuseAlbedo;
    
    float3 outputColor = diffuseTerm
        + specularTerm
        /*+ surfaceMaterial.emissiveColor*/;

    //outputColor = surfaceWorldPos / 1000.0; DEBUGGING
    u_Output[globalIdx] = float4(outputColor, 1);
}

// ---[ Miss Shader ]---

[shader("miss")]
void Miss(inout HitInfo payload : SV_RayPayload)
{
    payload.missed = true;
}
