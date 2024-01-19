//
//  PhotoDetailContainer+Helpers.swift
//  PicsumAppTests
//
//  Created by Tsz-Lung on 19/01/2024.
//

import Foundation
import ViewInspector
@testable import PicsumApp

extension PhotoDetailContainer {
    func authorText() throws -> String {
        try inspect()
            .find(viewWithAccessibilityIdentifier: "photo-detail-author")
            .text()
            .string()
    }
    
    func webURL() throws -> URL {
        try inspect()
            .find(viewWithAccessibilityIdentifier: "photo-detail-link")
            .link()
            .url()
    }
    
    func imageData() throws -> Data? {
        try inspect()
            .find(viewWithAccessibilityIdentifier: "photo-detail-image")
            .image()
            .actualImage()
            .uiImage().pngData()
    }
    
    func completePhotoImageLoading() async {
        await store.delegate.task?.value
    }
    
    var isShowingLoadingIndicator: Bool {
        let shimmer = try? inspect()
            .find(viewWithAccessibilityIdentifier: "photo-detail-image-stack")
            .modifier(Shimmer.self)
        return shimmer != nil
    }
    
    func isShowingReloadIndicator() throws -> Bool {
        try reloadIndicator().opacity() > 0
    }
    
    func simulateUserInitiateReload() throws {
        try reloadIndicator().tap()
    }
    
    private func reloadIndicator() throws -> InspectableView<ViewType.Button> {
        try inspect().find(viewWithAccessibilityIdentifier: "photo-detail-reload-button").button()
    }
}

