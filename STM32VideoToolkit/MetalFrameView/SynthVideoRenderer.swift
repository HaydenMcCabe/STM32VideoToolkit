//
//  SynthVideoRenderer.swift
//  STM32VideoToolkit
//
//  Created by Hayden McCabe on 7/24/23.
//

import Foundation
import SwiftUI
import MetalKit
import SynthVideo

fileprivate let tileMapBufferSize = 50 * 100
fileprivate let tileLibraryBufferSize = 12 * 256

class SynthVideoRenderer: NSObject, ObservableObject {
    let device: MTLDevice
    
    private var memoryStates = [SynthVideo.MemoryState]()
        
    // Metal hardware interface
    private let commandQueue: MTLCommandQueue
    // Pipelines
    private let fullScreenRenderPipeline: MTLComputePipelineState
    private let screenDrawPipeline: MTLComputePipelineState
    
    private let renderTexture: MTLTexture
    
    // Connection to a view
    public var view: MTKView? = nil
    
    var red: Float = 1
    var green: Float = 1
    var blue: Float = 1
    
    init?(device: MTLDevice) {
        self.device = device
        
        // Create references to the device hardware
        guard let commandQueue = device.makeCommandQueue() else {
            return nil
        }
        self.commandQueue = commandQueue
        
        // Create a texture to draw into
        let renderTextureDescriptor = MTLTextureDescriptor()
        renderTextureDescriptor.usage = [.shaderRead, .shaderWrite]
        renderTextureDescriptor.pixelFormat = .rgba8Unorm_srgb
        renderTextureDescriptor.storageMode = .private
        renderTextureDescriptor.width = 800
        renderTextureDescriptor.height = 600
        renderTextureDescriptor.textureType = .type2D
        guard let renderTexture = device.makeTexture(descriptor: renderTextureDescriptor) else {
            return nil
        }
        self.renderTexture = renderTexture
        
        // Prepare the compute pipelines
        let library = device.makeDefaultLibrary()
        
        guard
            let textureFunction = library?.makeFunction(name: "fullScreenRender"),
            let screenFunction = library?.makeFunction(name: "drawScreen")
        else {
            return nil
        }
        
        // Build the compute functions into pipelines
        do {
            fullScreenRenderPipeline = try device.makeComputePipelineState(function: textureFunction)
            screenDrawPipeline = try device.makeComputePipelineState(function: screenFunction)
        } catch {
            print("Unable to compile compute pipeline state.  Error info: \(error)")
            return nil
        }
    }

    func loadBuffers(memoryStates: [SynthVideo.MemoryState]) {
        // Look at the data here.
        self.memoryStates = memoryStates
    }
    
    func draw(frame: Int, red: Float, green: Float, blue: Float) {
        // Ensure we have a valid location to draw to.
        guard let view = view else {
            return
        }
        
        let tileMapData: Data
        let tileLibraryData: Data
        let xOffset: Int32
        let yOffset: Int32
        
        if frame < memoryStates.count {
            // Load proper data, if possible
            tileMapData = memoryStates[frame].tileMap
            tileLibraryData = memoryStates[frame].tileLibrary
            xOffset = Int32(memoryStates[frame].xOffset)
            yOffset = Int32(memoryStates[frame].yOffset)
        } else {
            // If the frame number isn't valid, display a blank screen
            tileMapData = Data(repeating: 0, count: 100 * 50)
            tileLibraryData = Data(repeating: 0, count: 12 * 256)
            xOffset = 0
            yOffset = 0
        }
        
        var tileMapBuffer: MTLBuffer? = nil
        tileMapData.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) in
            // Use the temporary buffer to load into GPU RAM
            tileMapBuffer = device.makeBuffer(bytes: ptr.baseAddress!, length: tileMapBufferSize)
        }
        var tileLibraryBuffer: MTLBuffer? = nil
        tileLibraryData.withUnsafeBytes { (ptr: UnsafeRawBufferPointer) in
            tileLibraryBuffer = device.makeBuffer(bytes: ptr.baseAddress!, length: tileLibraryBufferSize)
        }
        
        guard let tileMapBuffer, let tileLibraryBuffer else {
            return
        }
        
        
        // Create a buffer to submit this screen draw
        guard let screenDrawCommandBuffer = commandQueue.makeCommandBuffer(),
              let renderCommandEncoder = screenDrawCommandBuffer.makeComputeCommandEncoder()
            else {
            return
        }
        
        // Compute pass 1 : Render into a texture
        renderCommandEncoder.setComputePipelineState(fullScreenRenderPipeline)
        
        // Buffer 0 = tilemap
        // Buffer 1 = tileLibrary
        // Buffer 2 = color (float 4)
        // Texture 0 = Output texture
        renderCommandEncoder.setBuffer(tileMapBuffer, offset: 0, index: 0)
        renderCommandEncoder.setBuffer(tileLibraryBuffer, offset: 0, index: 1)
        var color = simd_float4(red, green, blue, 1.0)
        renderCommandEncoder.setBytes(&color, length: MemoryLayout<simd_float4>.size, index: 2)
        renderCommandEncoder.setTexture(renderTexture, index: 0)
        
        // Dispatch threads and submit command
        let renderThreadgroupSize = MTLSize(width: 800, height: 1, depth: 1)
        let renderGridSize = MTLSize(width: 800, height: 600, depth: 1)
        
        renderCommandEncoder.dispatchThreads(renderGridSize, threadsPerThreadgroup: renderThreadgroupSize)
        
        renderCommandEncoder.endEncoding()
        
        // Create the command encoder to draw into the screen
        guard let drawable = view.currentDrawable else {
            return
        }
        
        guard let screenDrawEncoder = screenDrawCommandBuffer.makeComputeCommandEncoder() else {
            return
        }
        screenDrawEncoder.setComputePipelineState(screenDrawPipeline)
        
        // Set the arguments for the command
        screenDrawEncoder.setTexture(renderTexture, index: 0)
        screenDrawEncoder.setTexture(drawable.texture, index: 1)
        
        var uniforms = ScreenDrawUniforms(screenWidth: Int32(drawable.texture.width),
                                          screenHeight: Int32(drawable.texture.height),
                                          xOffset: xOffset,
                                          yOffset: yOffset)

        screenDrawEncoder.setBytes(&uniforms, length: MemoryLayout<ScreenDrawUniforms>.size, index: 0)
        
        // Dispatch to threads
        let threadgroupSize = MTLSize(width: screenDrawPipeline.maxTotalThreadsPerThreadgroup, height: 1, depth: 1)
        let gridSize = MTLSize(width: drawable.texture.width, height: drawable.texture.height, depth: 1)
        screenDrawEncoder.dispatchThreads(gridSize, threadsPerThreadgroup: threadgroupSize)
        screenDrawEncoder.endEncoding()
        
        
        
        screenDrawCommandBuffer.present(drawable)
        screenDrawCommandBuffer.commit()
    }
}
