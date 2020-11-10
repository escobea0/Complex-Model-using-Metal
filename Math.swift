//
//  Math.swift
//  Blit Practice
//
//  Created by Evan Escobar on 11/10/20.
//

import Foundation
import simd


extension Float {
     var radianstodegrees: Float { return (self / Float.pi) * 180 }
     var degreestoradians: Float { return (self / 180) * Float.pi }
}


extension float4x4 {
     
     func returnthreebythree(FOUR: float4x4) -> float3x3 {
          let matrix = float3x3(
               [FOUR.columns.0.x, FOUR.columns.0.y, FOUR.columns.0.z],
               [FOUR.columns.1.x, FOUR.columns.1.y, FOUR.columns.1.z],
               [FOUR.columns.2.x, FOUR.columns.2.y, FOUR.columns.2.z]
          )
          return matrix
     }
     
     
     init(IDENTITY: Float) {
          let matrix = float4x4(
               [1, 0, 0, 0],
               [0, 1, 0, 0],
               [0, 0, 1, 0],
               [0, 0, 0, 1]
          )
          self = matrix
     }
     
     init(TRANSLATE: float3) {
          let matrix = float4x4(
               [1, 0, 0, 0],
               [0, 1, 0, 0],
               [0, 0, 1, 0],
               [TRANSLATE.x, TRANSLATE.y, TRANSLATE.z, 1]
          )
          self = matrix
     }
     
     init(SCALE: float3) {
          let matrix = float4x4(
               [SCALE.x, 0, 0, 0],
               [0, SCALE.y, 0 , 0],
               [0, 0, SCALE.z, 0],
               [0, 0 , 0, 1]
          )
          self = matrix
     }
     
     init(XROTATE: Float) {
          let matrix = float4x4(
               [1, 0, 0, 0],
               [0, cos(XROTATE), sin(XROTATE), 0],
               [0, -sin(XROTATE), cos(XROTATE), 0],
               [0, 0, 0, 1]
          )
          self = matrix
     }
     
     init(YROTATE: Float) {
          let matrix = float4x4(
               [cos(YROTATE), 0, -sin(YROTATE), 0],
               [0, 1, 0, 0],
               [sin(YROTATE), 0, cos(YROTATE), 0],
               [0, 0, 0, 1]
          )
          self = matrix
     }
     
     init(ZROTATE: Float) {
          let matrix = float4x4(
               [cos(ZROTATE), sin(ZROTATE), 0, 0],
               [-sin(ZROTATE), cos(ZROTATE), 0, 0],
               [0, 0, 1, 0],
               [0, 0, 0, 1]
          )
          self = matrix
     }
     
     init(FULLROTATION: float3) {
          let xrotation = float4x4(XROTATE: FULLROTATION.x)
          let yrotation = float4x4(YROTATE: FULLROTATION.y)
          let zrotation = float4x4(ZROTATE: FULLROTATION.z)
          self = xrotation * yrotation * zrotation
     }
     
     init(PROJECTION fov: Float, far: Float, near: Float, aspect: Float) {
          let matrix = float4x4(
               [ ((1 / tan(0.5 * fov)) / aspect),     0,                       0,                             0],
               [ 0,                                   1 / tan(0.5 * fov),      0,                             0],
               [ 0,                                   0,                       far/(far - near),              1],
               [ 0,                                   0,                       (far / (far - near)) * -near,  0]
          )
          self = matrix
     }
     
     
     init(projectionFov fov: Float, near: Float, far: Float, aspect: Float, lhs: Bool = true) {
       let y = 1 / tan(fov * 0.5)
       let x = y / aspect
       let z = lhs ? far / (far - near) : far / (near - far)
       let X = float4( x,  0,  0,  0)
       let Y = float4( 0,  y,  0,  0)
       let Z = lhs ? float4( 0,  0,  z, 1) : float4( 0,  0,  z, -1)
       let W = lhs ? float4( 0,  0,  z * -near,  0) : float4( 0,  0,  z * near,  0)
       self.init()
       columns = (X, Y, Z, W)
     }
     
     
     init(orthoLeft left: Float, right: Float, bottom: Float, top: Float, near: Float, far: Float) {
       let X = float4(2 / (right - left), 0, 0, 0)
       let Y = float4(0, 2 / (top - bottom), 0, 0)
       let Z = float4(0, 0, 1 / (far - near), 0)
       let W = float4((left + right) / (left - right),
                      (top + bottom) / (bottom - top),
                      near / (near - far),
                      1)
       self.init()
       columns = (X, Y, Z, W)
     }

     // left-handed LookAt
     init(eye: float3, center: float3, up: float3) {
       let z = normalize(center-eye)
       let x = normalize(cross(up, z))
       let y = cross(z, x)
       
       let X = float4(x.x, y.x, z.x, 0)
       let Y = float4(x.y, y.y, z.y, 0)
       let Z = float4(x.z, y.z, z.z, 0)
       let W = float4(-dot(x, eye), -dot(y, eye), -dot(z, eye), 1)
       
       self.init()
       columns = (X, Y, Z, W)
     }

     
}



