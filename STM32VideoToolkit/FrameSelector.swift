//
//  FrameSelector.swift
//  STM32VideoToolkit
//
//  Created by Hayden McCabe on 7/28/23.
//

import SwiftUI

struct FrameSelector: View {
    @Binding var frameNumber: Int
    let frameCount: Int
    
    private class FrameSelectorViewModel {
        var size: CGSize = .zero
    }
    @State private var state = FrameSelectorViewModel()
    @MainActor
    func updateSize(_ size: CGSize) {
        state.size = size
    }
    
    var drag: some Gesture {
        DragGesture(coordinateSpace: .local)
            .onChanged { gesture in
                // Find an approximation of the click position
                // rounded to an integer.
                let selectedFrame = Int((gesture.location.x / state.size.width) * CGFloat(frameCount))
                frameNumber = max(min(selectedFrame, frameCount - 1), 0)
            }
    }
    
    var body: some View {
        Canvas{ context, size in
            Task.detached {
                await updateSize(size)
            }
            
            // Find a width to fill
            guard frameNumber < frameCount else {
                return
            }
            let fillWidth = Float(size.width) * Float(frameNumber) / Float(frameCount-1)
            
            let fillPath = Path(roundedRect: CGRect(x: 0, y: 0, width: CGFloat(fillWidth), height: 10), cornerRadius: 0)
            context.fill(fillPath, with: .color(.red))
        }
        .frame(height: 10)
        .border(.white, width: 2)
        .gesture(drag)
        .onTapGesture { touchPoint in
            let selectedFrame = Int((touchPoint.x / state.size.width) * CGFloat(frameCount))
            frameNumber = max(min(selectedFrame, frameCount - 1), 0)
        }
    }
}

struct FrameSelector_Previews: PreviewProvider {
    static var previews: some View {
        FrameSelector(frameNumber: .constant(50), frameCount: 100)
    }
}
