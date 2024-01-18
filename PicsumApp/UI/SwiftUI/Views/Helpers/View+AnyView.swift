//
//  View+AnyView.swift
//  PicsumApp
//
//  Created by Tsz-Lung on 16/01/2024.
//

import SwiftUI

extension View {
    func eraseToAnyView() -> AnyView {
        AnyView(self)
    }
}
