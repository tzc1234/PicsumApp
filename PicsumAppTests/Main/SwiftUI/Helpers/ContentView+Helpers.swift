//
//  ContentView+Helpers.swift
//  PicsumAppTests
//
//  Created by Tsz-Lung on 22/01/2024.
//

import Foundation
import ViewInspector
import SwiftUI
@testable import PicsumApp

extension ContentView {
    func completePhotosLoading() async throws {
        try await photos().completePhotosLoading()
        try await Task.sleep(for: .seconds(0.01))
    }
    
    func photos() throws -> PhotoGridView<PhotoGridItemContainer, PhotoDetailContainer> {
        try inspect().find(PhotoGridView<PhotoGridItemContainer, PhotoDetailContainer>.self).actualView()
    }
    
    typealias PhotoView = InspectableView<ViewType.View<PhotoGridItemContainer>>
    
    func photoViews() async throws -> [PhotoView] {
        let photoViews = try inspect().findAll(PhotoGridItemContainer.self)
        for photoView in photoViews {
            try await photoView.completeImageDataLoading()
        }
        return photoViews
    }
    
    func triggerEnteringBackground() async throws {
        try outmostStack().callOnChange(oldValue: ScenePhase.active, newValue: ScenePhase.inactive)
        try await Task.sleep(for: .seconds(0.01))
    }
    
    private func outmostStack() throws -> InspectableView<ViewType.ClassifiedView> {
        try inspect().find(viewWithAccessibilityIdentifier: "content-view-outmost-stack")
    }
    
    func select(_ photo: Photo) throws {
        try inspect()
            .find(viewWithAccessibilityIdentifier: "photo-grid-photo-selection-button-\(photo.id)")
            .button()
            .tap()
    }
    
    func detailView() async throws -> PhotoDetailContainer {
        let detailView = try inspect()
            .find(PhotoDetailContainer.self)
            .actualView()
        await detailView.completePhotoImageLoading()
        return detailView
    }
}
