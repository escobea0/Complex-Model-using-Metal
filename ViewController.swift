//
//  ViewController.swift
//  Blit Practice
//
//  Created by Evan Escobar on 11/10/20.
//

import UIKit
import MetalKit

class ViewController: UIViewController, MTKViewDelegate {

     var metalview: MTKView!
     var metaldevice: MTLDevice!
     var metallibrary: MTLLibrary!
     var metalqueue: MTLCommandQueue!
     var depthstate: MTLDepthStencilState!
     
     var mesh1: MTKMesh!
     var mesh2: MTKMesh!
     var mesh3: MTKMesh!
     
     var state1: MTLRenderPipelineState!
     var state2: MTLRenderPipelineState!
     var state3: MTLRenderPipelineState!
     
     var texture1: MTLTexture!
     var texture2: MTLTexture!
     var texture3: MTLTexture!
     
     var timer = Float.zero
     var uniforms = UNIFORMS(projectionmatrix: float4x4(), viewmatrix: float4x4(), modelmatrix: float4x4(), shadowmartix: float4x4(), normalmatrix: float3x3())
     var fragmentuniforms = FRAGMENTUNIFORMS(lightcount: uint(), cameraposition: float3())
     var lights = [LIGHT]()
     
     var shadowtexture: MTLTexture!
     var shadowpass: MTLRenderPassDescriptor!
     var shadowstate: MTLRenderPipelineState!
     
     
     
     
     var defaultprojection = float4x4(PROJECTION: 120, far: 1000, near: 0.001, aspect: Float(UIScreen.main.bounds.width / UIScreen.main.bounds.height))
     var defaultview = float4x4(TRANSLATE: float3(0,-3,15))
     var defaultsun = LIGHT(position: float3(5,5,-2), color: float3(1,1,1), intensity: 1, type: .sun)
     var defaultambient = LIGHT(position: float3(0,0,0), color: float3(1,1,1), intensity: 0.25, type: .ambient)
     
     override func viewDidLoad() {
          super.viewDidLoad()

          self.view.backgroundColor = .white
          self.metaldevice = MTLCreateSystemDefaultDevice()
          self.metalview = MTKView()
          self.configure(metalview: self.metalview)
          self.view.addSubview(self.metalview)
          
          self.metallibrary = self.metaldevice.makeDefaultLibrary()
          self.metalqueue = self.metaldevice.makeCommandQueue()
          self.depthstate = self.createdepthstate()
          
          self.mesh1 = self.createbox(size: float3(3,1,3))
          self.state1 = self.createpipelinestate(mesh: self.mesh1, vertex: "vertexmain", fragment: "fragmentmain")
          self.texture1 = self.createtexture(name: "White Marble")
          
          self.mesh2 = self.createmodel(name: "dragon")
          
          self.lights.append(self.defaultsun)
          self.lights.append(self.defaultambient)
          self.fragmentuniforms.lightcount = uint(lights.count)
          self.fragmentuniforms.cameraposition = float3(0,0,10)
          
          self.shadowtexture = self.buildshadowtexture()
          self.shadowpass = self.buildshadowpass()
          self.shadowstate = self.buildshadowstate()
          
          
     }
     
     func configure(metalview: MTKView) {
          metalview.frame = UIScreen.main.bounds
          metalview.clearColor = MTLClearColor(red: 0.7, green: 0.8, blue: 1, alpha: 1)
          metalview.colorPixelFormat = .bgra8Unorm
          metalview.depthStencilPixelFormat = .depth32Float
          metalview.delegate = self
          metalview.device = self.metaldevice
          metalview.framebufferOnly = false
     }
     
     func createdepthstate() -> MTLDepthStencilState {
          let depthdescriptor = MTLDepthStencilDescriptor()
          depthdescriptor.depthCompareFunction = .less
          depthdescriptor.isDepthWriteEnabled = true
          let state = try? self.metaldevice.makeDepthStencilState(descriptor: depthdescriptor)
          return state!
     }
     
     func createbox(size: float3) -> MTKMesh {
          let allocator = MTKMeshBufferAllocator(device: self.metaldevice)
          let box = MDLMesh(boxWithExtent: size, segments: [1,1,1], inwardNormals: false, geometryType: .triangles, allocator: allocator)
          let mesh = try? MTKMesh(mesh: box, device: self.metaldevice)
          return mesh!
     }
     
     func createmodel(name: String) -> MTKMesh {
          let vertexdescriptor = MTLVertexDescriptor()
          vertexdescriptor.attributes[0].format = .float3
          vertexdescriptor.attributes[0].offset = 0
          vertexdescriptor.attributes[0].bufferIndex = 0
          vertexdescriptor.layouts[0].stride = 32
          
          let meshdescriptor = MTKModelIOVertexDescriptorFromMetal(vertexdescriptor)
          meshdescriptor.attributes[0] = MDLVertexAttribute(name: MDLVertexAttributePosition, format: .float3, offset: 0, bufferIndex: 0)
          meshdescriptor.attributes[1] = MDLVertexAttribute(name: MDLVertexAttributeNormal, format: .float3, offset: 12, bufferIndex: 0)
          meshdescriptor.attributes[2] = MDLVertexAttribute(name: MDLVertexAttributeTextureCoordinate, format: .float2, offset: 24, bufferIndex: 0)
          
          let allocator = MTKMeshBufferAllocator(device: self.metaldevice)
          let url = Bundle.main.url(forResource: name, withExtension: "obj")
          let asset = MDLAsset(url: url, vertexDescriptor: meshdescriptor, bufferAllocator: allocator)
          let model = asset.childObjects(of: MDLMesh.self).first as! MDLMesh
          model.addNormals(withAttributeNamed: MDLVertexAttributeNormal, creaseThreshold: 1)
          let mesh = try? MTKMesh(mesh: model, device: self.metaldevice)
          return mesh!
     }
     
     func createpipelinestate(mesh: MTKMesh, vertex: String, fragment: String) -> MTLRenderPipelineState {
          let descriptor = MTLRenderPipelineDescriptor()
          descriptor.vertexFunction = self.metallibrary.makeFunction(name: vertex)
          descriptor.fragmentFunction = self.metallibrary.makeFunction(name: fragment)
          descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
          descriptor.depthAttachmentPixelFormat = .depth32Float
          descriptor.vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(mesh.vertexDescriptor)
          let state = try? self.metaldevice.makeRenderPipelineState(descriptor: descriptor)
          return state!
     }
     
     func createtexture(name: String) -> MTLTexture {
          let loader = MTKTextureLoader(device: self.metaldevice)
          let data = UIImage(named: name)!.pngData()!
          let texture = try? loader.newTexture(data: data, options: [:])
          return texture!
     }
     
     func buildshadowtexture() -> MTLTexture {
          let texturedescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .depth32Float, width: Int(self.metalview.drawableSize.width), height: Int(self.metalview.drawableSize.height), mipmapped: false)
          texturedescriptor.usage = [.shaderRead, .renderTarget]
          texturedescriptor.storageMode = .private
          let texture = try? self.metaldevice.makeTexture(descriptor: texturedescriptor)
          return texture!
     }
     
     func buildshadowpass() -> MTLRenderPassDescriptor {
          let pass = MTLRenderPassDescriptor()
          pass.depthAttachment.texture = self.shadowtexture
          pass.depthAttachment.loadAction = .clear
          pass.depthAttachment.storeAction = .store
          pass.depthAttachment.clearDepth = 1
          return pass
     }
     
     func buildshadowstate() -> MTLRenderPipelineState {
          let descriptor = MTLRenderPipelineDescriptor()
          descriptor.vertexFunction = self.metallibrary.makeFunction(name: "vertexmaindepth")
          descriptor.fragmentFunction = nil
          descriptor.colorAttachments[0].pixelFormat = .invalid
          descriptor.depthAttachmentPixelFormat = .depth32Float
          descriptor.vertexDescriptor = MTKMetalVertexDescriptorFromModelIO(self.mesh1.vertexDescriptor)
          let state = try? self.metaldevice.makeRenderPipelineState(descriptor: descriptor)
          return state!
     }
     
     
     func draw(in view: MTKView) {
          timer += 0.01
          let descriptor = view.currentRenderPassDescriptor
          let buffer = self.metalqueue.makeCommandBuffer()
          
          let shadowencoder = buffer?.makeRenderCommandEncoder(descriptor: self.shadowpass)
          self.drawshadows(encoder: shadowencoder!)
         
          let encoder = buffer?.makeRenderCommandEncoder(descriptor: descriptor!)
          encoder?.setRenderPipelineState(self.state1)
          encoder?.setDepthStencilState(self.depthstate)
        
          self.uniforms.projectionmatrix = self.defaultprojection
          self.uniforms.viewmatrix = self.defaultview
          self.uniforms.modelmatrix = float4x4(YROTATE: timer)
          self.uniforms.normalmatrix = self.uniforms.modelmatrix.returnthreebythree(FOUR: self.uniforms.modelmatrix)
          self.setuniforms(encoder: encoder!)
          self.drawprimitives(encoder: encoder!, mesh: self.mesh1)
          
          self.uniforms.modelmatrix = float4x4(TRANSLATE: float3(0,0.5,0)) * float4x4(YROTATE: timer) * float4x4(SCALE: float3(3,3,3))
          self.uniforms.normalmatrix = self.uniforms.modelmatrix.returnthreebythree(FOUR: self.uniforms.modelmatrix)
          self.setuniforms(encoder: encoder!)
          self.drawprimitives(encoder: encoder!, mesh: self.mesh2)
          
          encoder?.endEncoding()
          let drawable = self.metalview.currentDrawable!
          buffer?.present(drawable)
          buffer?.commit()
     }
     
     func drawshadows(encoder: MTLRenderCommandEncoder) {
          encoder.setCullMode(.none)
          encoder.setDepthBias(0.01, slopeScale: 1, clamp: 0.01)
          encoder.setRenderPipelineState(self.shadowstate)
          encoder.setDepthStencilState(self.depthstate)
          
          self.uniforms.projectionmatrix = float4x4(orthoLeft: -8, right: 8, bottom: -8, top: 8, near: 0.01, far: 16)
          self.uniforms.viewmatrix = float4x4(eye: self.defaultsun.position, center: float3(0,0,0), up: float3(0,1,0))
          self.uniforms.shadowmartix = self.uniforms.projectionmatrix * self.uniforms.viewmatrix
          
          
          self.uniforms.modelmatrix = float4x4(YROTATE: timer)
          self.uniforms.normalmatrix = self.uniforms.modelmatrix.returnthreebythree(FOUR: self.uniforms.modelmatrix)
          self.setuniforms(encoder: encoder)
          self.drawprimitives(encoder: encoder, mesh: self.mesh1)
          
          self.uniforms.modelmatrix = float4x4(TRANSLATE: float3(0,0.5,0)) * float4x4(YROTATE: timer) * float4x4(SCALE: float3(3,3,3))
          self.uniforms.normalmatrix = self.uniforms.modelmatrix.returnthreebythree(FOUR: self.uniforms.modelmatrix)
          self.setuniforms(encoder: encoder)
          self.drawprimitives(encoder: encoder, mesh: self.mesh2)

          encoder.endEncoding()
     }
     
     
     func setuniforms(encoder: MTLRenderCommandEncoder) {
          encoder.setVertexBytes(&uniforms, length: MemoryLayout<UNIFORMS>.stride, index: 1)
          
          encoder.setFragmentBytes(&fragmentuniforms, length: MemoryLayout<FRAGMENTUNIFORMS>.stride, index: 2)
          encoder.setFragmentBytes(&lights, length: MemoryLayout<LIGHT>.stride * lights.count, index: 3)
          encoder.setFragmentTexture(self.shadowtexture, index: 0)
          encoder.setFragmentTexture(self.texture1, index: 1)
     }
     
     func drawprimitives(encoder: MTLRenderCommandEncoder, mesh: MTKMesh) {
          encoder.setVertexBuffer(mesh.vertexBuffers[0].buffer, offset: 0, index: 0)
          for mesh in mesh.submeshes {
               encoder.drawIndexedPrimitives(type: .triangle, indexCount: mesh.indexCount, indexType: mesh.indexType, indexBuffer: mesh.indexBuffer.buffer, indexBufferOffset: mesh.indexBuffer.offset)
          }
     }
     
     func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
          
     }

}

