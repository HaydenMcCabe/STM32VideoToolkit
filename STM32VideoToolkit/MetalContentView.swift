//
//  MetalContentView.swift
//  STM32VideoToolkit
//
//  Created by Hayden McCabe on 7/24/23.
//

import SwiftUI
import MetalKit
import Combine
import SynthVideo
import CoreGraphics
import AVKit

struct MetalContentView: View {
    @ObservedObject private var vm = ViewModel()
    
    @EnvironmentObject var renderer: SynthVideoRenderer
    
    var body: some View {
        ZStack {
            // Make the background of the window black
            Color.black
            
            HStack {
                VStack {
                    if vm.errorText.count > 0 && !vm.fullscreen {
                        Text(vm.errorText)
                    }
                    MetalView()
                        .aspectRatio(CGSize(width: 4, height: 3), contentMode: .fit)
                        .overlay {
                            // Video control elements on the bottom of the video display.
                            if (vm.videoUI) {
                                VStack {
                                    Spacer()
                                    HStack {
                                        Button {
                                            vm.isPlaying.toggle()
                                        } label: {
                                            vm.isPlaying ? Image(systemName: "pause.fill") : Image(systemName: "play.fill")
                                        }
                                        FrameSelector(frameNumber: $vm.frameNumber, frameCount: vm.video?.frames.count ?? 0)
                                        Button {
                                            withAnimation {
                                                vm.fullscreen.toggle()
                                            }
                                        } label: {
                                            Image(systemName:
                                                    vm.fullscreen ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                                        }
                                    }
                                    .disabled(vm.video == nil)
                                }
                            }
                        }
                        .onHover(perform: { hovering in
                            vm.videoUI = hovering
                        })
                    if (!vm.fullscreen) {
                        HStack {
                            Button {
                                initFromDat()
                            } label: {
                                Text("Load .dat")
                            }
                            
                            Button {
                                initFromScript()
                            } label: {
                                Text("Load Script")
                            }
                            
                            Button {
                                exportMP4()
                            } label: {
                                Text("Export MP4")
                            }
                            .disabled(vm.video == nil)
                            
                            Button {
                                exportSynthvid()
                            } label: {
                                Text("Export .dat")
                            }
                            .disabled(vm.video == nil)
                        }
                        .padding()
                    }
                }
                
                if (!vm.fullscreen) {
                    // Color controls
                    VStack {
                        Spacer()
                        RotarySlider(value: $vm.red, in: 0...1, onColor: .red)
                        Spacer()
                        RotarySlider(value: $vm.green, in: 0...1, onColor: .green)
                        Spacer()
                        RotarySlider(value: $vm.blue, in: 0...1, onColor: .blue)
                        Spacer()
                    }
                    .frame(width: 50)
                    .padding()
                }
            }
            .onChange(of: vm.frameNumber) { newValue in
                renderer.draw(frame: vm.frameNumber, red: vm.red, green: vm.green, blue: vm.blue)
            }
            .onChange(of: vm.red) { newValue in
                renderer.draw(frame: vm.frameNumber, red: vm.red, green: vm.green, blue: vm.blue)
            }
            .onChange(of: vm.green) { newValue in
                renderer.draw(frame: vm.frameNumber, red: vm.red, green: vm.green, blue: vm.blue)
            }
            .onChange(of: vm.blue) { newValue in
                renderer.draw(frame: vm.frameNumber, red: vm.red, green: vm.green, blue: vm.blue)
            }
            .onChange(of: vm.isPlaying) { newValue in
                if vm.isPlaying {
                    // If there is a video, play it
                    guard let video = vm.video else {
                        return
                    }
                    
                    // If the video is at the end of the video, reset to 0
                    if vm.frameNumber >= (video.frames.count - 1) {
                        vm.frameNumber = 0
                    }
                    
                    // Start playing the video by creating a timer that
                    // increases the frame number every 1/30 seconds.
                    vm.playTimer = Timer.publish(every: 1/30.0, on: .main, in: .common).autoconnect().sink(receiveValue: { [self] _ in
                        // Advance the frame by one, if possible
                        guard let frameCount = vm.video?.frames.count else {
                            return
                        }
                        
                        if vm.frameNumber < (frameCount - 1) {
                            vm.frameNumber += 1
                            renderer.draw(frame: vm.frameNumber, red: vm.red, green: vm.green, blue: vm.blue)
                        } else {
                            // The end of the video has been reached; replay from 0
                            vm.frameNumber = 0
                        }
                        
                    })
                } else {
                    // When not playing, don't have a play timer
                    vm.playTimer = nil
                }
            }
            
            // Overlay on the entire UI
            if (vm.overlayEnabled) {
                VStack {
                    ProgressView()
                        .padding()
                    Text(vm.overlayText)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black)
                .opacity(0.9)
            }
        }
    }
    
    func initFromDat() {
        vm.isPlaying = false
        
        guard let datFile = showOpenPanel() else {
            return
        }
        
        vm.errorText = ""
        vm.overlayEnabled = true
        vm.overlayText = "Loading from file."
        
        Task.detached(priority: .userInitiated) {
            defer {
                DispatchQueue.main.async {
                    vm.overlayEnabled = false
                }
            }
            
            do {
                let romVideo = try SynthVideo(synthvidFile: datFile)
                DispatchQueue.main.async {
                    vm.video = romVideo
                    renderer.loadBuffers(memoryStates: romVideo.memoryStates)
                    vm.frameNumber = 0
                }
                
            } catch {
                DispatchQueue.main.async {
                    vm.video = nil
                    vm.frameNumber = 0
                    vm.overlayEnabled = false
                    vm.errorText = error.localizedDescription
                }
            }
        }
    }
    
    func initFromScript() {
        vm.isPlaying = false
        
        guard let scriptFile = showOpenPanel() else {
            return
        }
        
        vm.errorText = ""
        vm.overlayEnabled = true
        vm.overlayText = "Loading from script."
        
        Task.detached(priority: .userInitiated) {
            defer {
                DispatchQueue.main.async {
                    vm.overlayEnabled = false
                }
            }
            
            do {
                let romVideo = try SynthVideo(script: scriptFile)
                DispatchQueue.main.async {
                    vm.video = romVideo
                    renderer.loadBuffers(memoryStates: romVideo.memoryStates)
                    vm.frameNumber = 0
                }
                
            } catch {
                DispatchQueue.main.async {
                    vm.video = nil
                    vm.frameNumber = 0
                    vm.overlayEnabled = false
                    vm.errorText = error.localizedDescription
                }
            }
        }
    }
    
    func exportMP4() {
        guard let saveURL = showSavePanel(contentType: .mpeg4Movie) else {
            return
        }
        
        vm.errorText = ""
        vm.overlayEnabled = true
        vm.overlayText = "Exporting to MP4 video."
        
        Task.detached() {
            defer {
                DispatchQueue.main.async {
                    vm.overlayEnabled = false
                }
            }
            do {
                let color = await CGColor(red: CGFloat(vm.red), green: CGFloat(vm.green), blue: CGFloat(vm.blue), alpha: 1.0)
                guard let video = await vm.video else {
                    return
                }
                try video.exportVideo(url: saveURL, range: nil, color: color)
            } catch {
                DispatchQueue.main.async {
                    vm.overlayEnabled = false
                    vm.errorText = error.localizedDescription
                }
            }
        }
    }
    
    func exportSynthvid() {
        guard let saveURL = showSavePanel(contentType: .data) else {
            return
        }
        
        vm.errorText = ""
        vm.overlayEnabled = true
        vm.overlayText = "Exporting to Synthvid file."

        Task.detached() {
            defer {
                DispatchQueue.main.async {
                    vm.overlayEnabled = false
                }
            }
            do {
                guard let video = await vm.video else {
                    return
                }
                try video.exportSynthvid(url: saveURL)
            } catch {
                DispatchQueue.main.async {
                    vm.overlayEnabled = false
                    vm.errorText = error.localizedDescription
                }
            }
        }
    }
    
    private func showSavePanel(contentType: UTType, title: String? = "Save", message: String? = "") -> URL? {
        let savePanel = NSSavePanel()
        savePanel.allowedContentTypes = [contentType]
        savePanel.canCreateDirectories = true
        savePanel.isExtensionHidden = false
        savePanel.allowsOtherFileTypes = false
        savePanel.title = title
        savePanel.message = message
        savePanel.nameFieldLabel = "File name:"
        
        let response = savePanel.runModal()
        return response == .OK ? savePanel.url : nil
    }
    
    private func showOpenPanel() -> URL? {
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [.delimitedText, .text, .data]
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        openPanel.canChooseFiles = true
        let response = openPanel.runModal()
        return response == .OK ? openPanel.url : nil
    }
}

extension MetalContentView {
    class ViewModel: ObservableObject {
        @Published var frameNumber: Int = 0
        @Published var red: Float = 1.0
        @Published var green: Float = 1.0
        @Published var blue: Float = 1.0

        @Published var isPlaying: Bool = false
        @Published var video: SynthVideo? = nil
        
        @Published var overlayEnabled: Bool = false
        @Published var overlayText: String = ""
        
        @Published var fullscreen: Bool = false
        @Published var videoUI: Bool = true
        
        @Published var errorText = ""
        
        var playTimer: AnyCancellable? = nil
        var videoUITimer: AnyCancellable? = nil
        
        // Register with the OS to receive keyboard events
        var eventHandler: Any? = nil
        
        // Initializer
        init()
        {
            addKeyboardMonitoring()
        }

        func addKeyboardMonitoring() {
            eventHandler = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                switch event.keyCode {
                case 123: // Left key
                    self.isPlaying = false
                    if self.frameNumber >= 1 {
                        self.frameNumber -= 1
                    }
                    return nil
                case 124: // Right key
                    self.isPlaying = false
                    if self.frameNumber <= self.video?.frames.count ?? 0  {
                        self.frameNumber += 1
                    }
                    return nil
                case 49: // Space bar
                    self.isPlaying.toggle()
                    return nil
                case 53: // Escape
                    withAnimation {
                        self.fullscreen = false
                    }
                    return nil
                default:
                    return event
                }
            }
        }
        
        func pingVideoUI() {
            // Replace an existing timer with a new one
            if let videoUITimer {
                videoUITimer.cancel()
            }
        }
    }
}

struct MetalContentView_Previews: PreviewProvider {
    static var previews: some View {
        MetalContentView()
            .environmentObject({ () -> SynthVideoRenderer in
                let device = MTLCreateSystemDefaultDevice()!
                return SynthVideoRenderer(device: device)!
            }())
    }
}
