//
//  ImageSequenceExportView.swift
//  STM32VideoToolkit
//
//  Created by Hayden McCabe on 4/5/23.
//

import SwiftUI
import SynthVideo

fileprivate let cgRed = CGColor.init(red: 1, green: 0, blue: 0, alpha: 1)
fileprivate let cgGreen = CGColor.init(red: 0, green: 1, blue: 0, alpha: 1)
fileprivate let cgBlue = CGColor.init(red: 0, green: 0, blue: 1, alpha: 1)
fileprivate let cgCyan = CGColor.init(red: 0, green: 1, blue: 1, alpha: 1)
fileprivate let cgMagenta = CGColor.init(red: 1, green: 0, blue: 1, alpha: 1)
fileprivate let cgYellow = CGColor.init(red: 1, green: 1, blue: 0, alpha: 1)
fileprivate let cgWhite = CGColor.init(red: 1, green: 1, blue: 1, alpha: 1)


struct ImageSequenceExportView: View {
    @Environment(\.dismiss) private var dismiss
    
    var video: SynthVideo
    var color: CGColor
    
    @State private var baseFileName = "image"
    @State private var exportFolder: URL? = nil
    @State private var messageText = ""
    @State private var isExporting = false
    
    private var exportFolderString: String {
        exportFolder?.absoluteString ?? "<No folder selected>"
    }
    
    var body: some View {
        VStack {
            Grid {
                // Each grid row has two items
                GridRow {
                    Text("Base filename:")
                    TextField("Base filename:", text: $baseFileName)
                }
                GridRow {
                    Text("Export folder:")
                    Text(exportFolderString)
                    Button(action: selectOutputFolder) {
                        Image(systemName: "folder")
                    }
                }
                Divider()
                GridRow {
                    Text("")
                    Button("Cancel") {
                        dismiss()
                    }
                    
                    Button("Export") {
                        isExporting = true
                        Task.detached(priority: .background) {
                            do {
                                try await video.exportImageSequence(outputFolder: exportFolder!, baseFilename: baseFileName, colors: [color])
                                DispatchQueue.main.async {
                                    isExporting = false
                                    dismiss()
                                }
                                
                            } catch {
                                DispatchQueue.main.async {
                                    isExporting = false
                                    messageText = error.localizedDescription
                                }
                            }
                        }
                    }
                    .disabled(!readyForExport)
                    
                    Button("Export multicolor") {
                        isExporting = true
                        Task.detached(priority: .background) {
                            do {
                                
                                try await video.exportImageSequence(outputFolder: exportFolder!, baseFilename: baseFileName, colors: [cgRed, cgGreen, cgBlue, cgCyan, cgMagenta, cgYellow, cgWhite])
                                DispatchQueue.main.async {
                                    isExporting = false
                                    dismiss()
                                }
                                
                            } catch {
                                DispatchQueue.main.async {
                                    isExporting = false
                                    messageText = error.localizedDescription
                                }
                            }
                        }
                        
                    }
                    .disabled(!readyForExport)
                }
            }
            .disabled(isExporting)
            
            Text(messageText)
        }
        .padding(30)
        .overlay {
            ZStack {
                Color.black.opacity(0.7)
                ProgressView()
            }
            .opacity(isExporting ? 1 : 0)
        }
    }
    
    func selectOutputFolder() {
        let openPanel = NSOpenPanel()
        openPanel.allowedContentTypes = [.delimitedText, .text, .data]
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = true
        openPanel.canChooseFiles = false
        openPanel.canCreateDirectories = true
        
        let response = openPanel.runModal()
        //return response == .OK ? openPanel.url : nil
        
        guard response == .OK,
              let folderURL = openPanel.url,
              (try! folderURL.resourceValues(forKeys: [.isDirectoryKey])).isDirectory ?? false
            else {
            return
        }
        exportFolder = folderURL
    }
    
    var readyForExport: Bool {
        guard let folderURL = exportFolder,
              (try! folderURL.resourceValues(forKeys: [.isDirectoryKey])).isDirectory ?? false,
              !baseFileName.isEmpty
        else {
            return false
        }
        
        return true
    }
}
