//
//  SynthVidPlayer.swift
//  STM32VideoToolkit
//
//  Created by Hayden McCabe on 7/19/23.
//

import SwiftUI
import MetalKit
import SynthVideo

struct MetalView: NSViewRepresentable {

    typealias NSViewType = MTKView
    
    @EnvironmentObject var renderer: SynthVideoRenderer
    
    func makeNSView(context: Context) -> MTKView {
        // Create a Metal view and connect it to the device
        // used by the renderer
        let view = MTKView(frame: .zero, device: renderer.device)
        view.framebufferOnly = false
        
        renderer.view = view
        return view
    }
    
    func updateNSView(_ nsView: MTKView, context: Context) {
    }
    
}
