//
//  Structures.swift
//  Blit Practice
//
//  Created by Evan Escobar on 11/10/20.
//

import Foundation
import simd

struct UNIFORMS {
     var projectionmatrix: float4x4;
     var viewmatrix: float4x4;
     var modelmatrix: float4x4;
     var shadowmartix: float4x4;
     var normalmatrix: float3x3;
}

struct FRAGMENTUNIFORMS {
     var lightcount: uint;
     var cameraposition: float3;
}

struct LIGHT {
     var position: float3;
     var color: float3;
     var intensity: Float;
     var type: LIGHTTYPE;
}

enum LIGHTTYPE: Int {
     case sun = 0
     case ambient = 1 
}
