//
//  PhotoGridView+Helpers.swift
//  PicsumAppTests
//
//  Created by Tsz-Lung on 18/01/2024.
//

import Foundation
import ViewInspector
@testable import PicsumApp

extension PhotoGridView {
    func completePhotosLoading() async {
        await store.delegate.loadPhotosTask?.value
    }
    
    func completeLoadMorePhotos() async {
        await store.delegate.loadMorePhotosTask?.value
    }
    
    @MainActor
    func simulateUserInitiateReload() {
        // ViewInspector does not support SwiftUI refreshable yet, therefore directly trigger the loadPhotos()
        store.loadPhotos()
    }
    
    var photosLoadingTask: Task<Void, Never>? {
        store.delegate.loadPhotosTask
    }
    
    var isShowingLoadingIndicator: Bool {
        store.isLoading
    }
    
    func photoView(at index: Int) throws -> PhotoGridItem {
        try photoViews()[index]
    }
    
    func photoViews() throws -> [PhotoGridItem] {
        try inspectablePhotoViews().map { try $0.actualView() }
    }
    
    private func inspectablePhotoViews() throws -> [InspectableView<ViewType.View<PhotoGridItem>>] {
        try inspect().findAll(PhotoGridItem.self)
    }
    
    func inspectablePhotoViewContainers() throws -> [InspectableView<ViewType.View<PhotoGridItemContainer>>] {
        try inspect().findAll(PhotoGridItemContainer.self)
    }
    
    func errorView() throws -> InspectableView<ViewType.Alert> {
        try inspect().find(viewWithAccessibilityIdentifier: "photo-grid-outmost-view").alert()
    }
}

extension InspectableView<ViewType.View<PhotoGridItemContainer>> {
    func completeImageDataLoading() async throws {
        try await actualView().store.delegate.task?.value
    }
    
    func simulatePhotoViewInvisible() throws {
        try stack().callOnDisappear()
    }
    
    func simulatePhotoViewVisible() throws {
        try stack().callOnAppear()
    }
    
    private func stack() throws -> InspectableView<ViewType.ClassifiedView> {
        try find(viewWithAccessibilityIdentifier: "photo-grid-item-container-stack")
    }
    
    func imageData() throws -> Data? {
        try photoView().imageData
    }
    
    private func photoView() throws -> PhotoGridItem {
        try find(PhotoGridItem.self).actualView()
    }
}

extension InspectableView<ViewType.Alert> {
    func titleText() throws -> String {
        try title().string()
    }
    
    func messageText() throws -> String {
        try message().text().string()
    }
    
    func actionButton() throws -> InspectableView<ViewType.Button> {
        try actions().button()
    }
}
