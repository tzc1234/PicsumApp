//
//  PhotoGridItem+Helpers.swift
//  PicsumAppTests
//
//  Created by Tsz-Lung on 18/01/2024.
//

import Foundation
import ViewInspector
@testable import PicsumApp

extension PhotoGridItem {
    func authorText() throws -> String {
        try inspect()
            .find(viewWithAccessibilityIdentifier: "photo-grid-item-author")
            .text()
            .string()
    }
    
    func imageData() throws -> Data? {
        try inspect()
            .find(viewWithAccessibilityIdentifier: "photo-grid-item-image")
            .image()
            .actualImage()
            .uiImage()
            .pngData()
    }
    
    var isShowingLoadingIndicator: Bool {
        let shimmer = try? inspect()
            .find(viewWithAccessibilityIdentifier: "photo-grid-item-background")
            .modifier(Shimmer.self)
        return shimmer != nil
    }
}
