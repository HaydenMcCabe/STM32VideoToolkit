//
//  RotarySlider.swift
//  STM32VideoToolkit
//
//  Created by Hayden McCabe on 8/1/23.
//

import SwiftUI

struct RotarySlider<T: RotarySliderBindable>: View {
    @Binding var value: T
    let range: ClosedRange<T>
    let width: Double
    let onColor: Color
        
    init(value: Binding<T>,
         in range: ClosedRange<T>,
         width: Double = 1.5 * .pi,
         onColor: Color = .accentColor,
         lineWidth: Double = 3) {
        self._value = value
        self.range = range
        self.width = width
        self.onColor = onColor
    }
    
    // Keep a reference to the last known size of the view
    private class RotarySliderViewModel {
        var size: CGSize = .zero
    }
    @State private var state = RotarySliderViewModel()
    @MainActor
    func updateSize(_ size: CGSize) {
        state.size = size
    }
    
    // The drag gesture will set the value based on the angle
    // between the drag point and the view's center.
    var drag: some Gesture {
        DragGesture(coordinateSpace: .local)
            .onChanged { gesture in
                // Find the sides of a triangle between
                // this point and the center of the view
                let xCenter = state.size.width / 2
                let yCenter = state.size.height / 2
                
                let xSide = gesture.location.x - xCenter
                let ySide = gesture.location.y - yCenter
                
                // Find the angle relative to the up (negative y) axis
                let touchAngle = atan2(xSide, -ySide)
                // Change the bound value based on the user input.
                // Angles out of the bounds set by the width are
                // clamped to the given range.
                let theta = width/2
                if touchAngle < -theta {
                    value = range.lowerBound
                } else if touchAngle > theta {
                    value = range.upperBound
                } else {
                    // Map the range -theta ... theta
                    // to the slider's range.
                    let normalized = (touchAngle + theta) / width
                    // Make an estimate to a value in the range
                    // using the double values, then cast to the
                    // appropriate type
                    let estimate = normalized * (range.upperBound.double - range.lowerBound.double) + (range.lowerBound.double)
                    value = T(estimate)
                }
                
            }
    }
        
    var body: some View {
        Canvas { context, size in
            // Update the view size on another thread
            Task.detached {
                await updateSize(size)
            }
            
            // Normalize the value's position in the range
            let minValue = range.lowerBound.double
            let maxValue = range.upperBound.double
            let progress = (value.double - minValue) / (maxValue - minValue)
            
            // Calculate the geometry.
            let radius = (min(size.width, size.height) / 2)
            let cgCenter = CGPoint(x: size.width/2, y: size.height/2)
            let theta = width / 2
            let upAngle = -Double.pi / 2
            let startAngle = Angle(radians: upAngle - theta)
            let endAngle = Angle(radians: upAngle + theta)

            // Find the colors needed to draw
            let offColor = onColor.opacity(0.3)
            
            // Draw the arc with a gradient that shows the progress
            
            // The gradient describes a full circle. Scale the progress to the visible
            // part of the arc
            let gradientProgress = progress * (width / (2 * .pi))
            let trackRadius = 0.95 * radius
            let trackGradient = Gradient(stops:
                                        [Gradient.Stop(color: onColor, location: 0),
                                         Gradient.Stop(color: onColor, location: gradientProgress),
                                         Gradient.Stop(color: offColor, location: gradientProgress),
                                         Gradient.Stop(color: offColor, location: 1)])
            let trackShader = GraphicsContext.Shading.conicGradient(trackGradient, center: cgCenter, angle: startAngle)
            var arcPath = Path()
            arcPath.addArc(center: cgCenter, radius: trackRadius, startAngle: startAngle, endAngle: endAngle, clockwise: false)
            context.stroke(arcPath, with: trackShader, style: StrokeStyle(lineWidth: 0.1 * radius))
                        
            // Draw an indicator that points to the selected value
            var indicatorPath = Path()
            let indicatorLength = 0.8 * radius
            indicatorPath.move(to: cgCenter)
            let indicatorEnd = CGPointMake(cgCenter.x, cgCenter.y - indicatorLength)
            indicatorPath.addLine(to: indicatorEnd)
            indicatorPath.closeSubpath()
            // Map the progress from 0...1 to -theta...theta
            let indicatorAngle = (theta * 2 * (progress - 0.5))
            // Rotate the indicator
            let rotatedIndicator = indicatorPath.rotation(Angle(radians: indicatorAngle), anchor: .center)
            context.stroke(rotatedIndicator.path(
                            in: CGRect(origin: .zero, size: size)),
                            with: .color(red: 1, green: 1, blue: 1),
                            style: StrokeStyle(lineWidth: 5))
            
            // Draw a color dot in the center
            // Define a CGRect that contains the dot
            let dotRadius = 0.1 * radius
            let dotRect = CGRect(x: cgCenter.x - dotRadius, y: cgCenter.y - dotRadius, width: 2 * dotRadius, height: 2 * dotRadius)
            let dotPath = Path(ellipseIn: dotRect)
            
            context.fill(dotPath, with: .color(onColor))
        }
        .gesture(drag)
    }
}

struct RotarySlider_Previews: PreviewProvider {
    static var previews: some View {
        RotarySlider(
            value: .constant(Int(19)),
            in: (-25 ... 30),
            onColor: .green)
    }
}
