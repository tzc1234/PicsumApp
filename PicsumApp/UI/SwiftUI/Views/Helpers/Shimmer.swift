//
//  Shimmer.swift
//  PicsumApp
//
//  Created by Tsz-Lung on 12/01/2024.
//

import SwiftUI

struct Shimmer: ViewModifier {
    @State private var isInitial = true
    private let animation: Animation
    private let gradient: Gradient
    private let min: CGFloat
    private let max: CGFloat
    
    init(bandSize: CGFloat) {
        self.animation = Animation.linear(duration: 1.25).delay(0.25).repeatForever(autoreverses: false)
        self.gradient = Gradient(colors: [.white.opacity(0.75), .white, .white.opacity(0.75)])
        self.min = 0 - bandSize
        self.max = 1 + bandSize
    }
    
    private var startPoint: UnitPoint {
        isInitial ? UnitPoint(x: min, y: min) : UnitPoint(x: 1, y: 1)
    }
    
    private var endPoint: UnitPoint {
        isInitial ? UnitPoint(x: 0, y: 0) : UnitPoint(x: max, y: max)
    }
    
    func body(content: Content) -> some View {
        content
            .mask(LinearGradient(gradient: gradient, startPoint: startPoint, endPoint: endPoint))
            .animation(animation, value: isInitial)
            .onAppear { isInitial = false }
    }
}

extension View {
    @ViewBuilder 
    func shimmering(active: Bool = true, bandSize: CGFloat = 0.3) -> some View {
        if active {
            modifier(Shimmer(bandSize: bandSize))
        } else {
            self
        }
    }
}
