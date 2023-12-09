//
//  STM32VideoToolkitApp.swift
//  STM32VideoToolkit
//
//  Created by Hayden McCabe on 12/28/22.
//

import SwiftUI
import SynthVideo

@main
struct STM32VideoToolkitApp: App {
    
    let renderer: SynthVideoRenderer?
    
    init() {
        if let device = MTLCreateSystemDefaultDevice() {
            renderer = SynthVideoRenderer(device: device)    
        } else {
            renderer = nil
        }
    }
    
    var body: some Scene {
        WindowGroup {
            if let renderer {
                MetalContentView()
                    .environmentObject(renderer)
                    .background(Color.black)
                    
            } else {
                Text("Unable to initialize metal device.")
            }
        }
    }
}
