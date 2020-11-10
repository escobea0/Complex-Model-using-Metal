//
//  Shaders.metal
//  Blit Practice
//
//  Created by Evan Escobar on 11/10/20.
//

#include <metal_stdlib>
using namespace metal;
#include <simd/simd.h>

struct VIN {
     float4 position [[attribute(0)]];
     float3 normal [[attribute(1)]];
     float2 coords [[attribute(2)]];
};

struct VOUT {
     float4 position [[position]];
     float3 normal;
     float2 coords;
     float4 shadowposition;
};

//

struct UNIFORMS {
     float4x4 projectionmatrix;
     float4x4 viewmatrix;
     float4x4 modelmatrix;
     float4x4 shadowmatrix;
     float3x3 normalmatrix;
};

struct FRAGMENTUNIFORMS {
     uint lightcount;
     float3 cameraposition;
};

enum LIGHTTYPE {
     sun = 0,
     ambient = 1
};

struct LIGHT {
     float3 position;
     float3 color;
     float intensity;
     LIGHTTYPE type;
};

//

vertex VOUT vertexmain(const VIN in [[stage_in]],
                       constant UNIFORMS &data [[buffer(1)]])
{
     VOUT out;
     out.position = data.projectionmatrix * data.viewmatrix * data.modelmatrix * in.position;
     out.normal = data.normalmatrix * in.normal;
     out.coords = in.coords;
     out.shadowposition = data.shadowmatrix * data.modelmatrix * in.position;
     return out;
}

vertex float4 vertexmaindepth(const VIN in [[stage_in]],
                              constant UNIFORMS &data [[buffer(1)]])
{
     float4 position = data.projectionmatrix * data.viewmatrix * data.modelmatrix * in.position;
     return position;
}


//
     
     
fragment float4 fragmentmain(const VOUT in [[stage_in]],
                             constant FRAGMENTUNIFORMS &data [[buffer(2)]],
                             constant LIGHT *lights [[buffer(3)]],
                             depth2d<float> shadowtexture [[texture(0)]],
                             texture2d<float> texture1 [[texture(1)]])
{

     constexpr sampler sampler;
     float3 basecolor = texture1.sample(sampler, in.coords).rgb;
     float3 diffusecolor = 0;
     float3 ambientcolor = 0;
     float3 normaldirection = normalize(in.normal);
     
     for (uint i = 0 ; i < data.lightcount ; i++) {
          LIGHT light = lights[i];
          if (light.type == sun) {
               float3 lightdirection = normalize(-light.position);
               float diffuseintensity = saturate(-dot(lightdirection, normaldirection));
               diffusecolor = light.color * basecolor * diffuseintensity;
          } else if (light.type == ambient) {
               ambientcolor = light.color * light.intensity;
          }
     }
     
     float2 coords = in.shadowposition.xy;
     coords = coords * 0.5 + 0.5;
     coords.y = 1 - coords.y;
     float shadowsample = shadowtexture.sample(sampler, coords);
     float currentsample = in.shadowposition.z / in.shadowposition.w;
     if (currentsample > shadowsample) {
          diffusecolor = diffusecolor * 0.25;
     }

     float3 color = diffusecolor + ambientcolor;
     return float4(color, 1);

}

