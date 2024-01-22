//
//  PhotoGridAcceptanceTests.swift
//  PicsumAppTests
//
//  Created by Tsz-Lung on 22/01/2024.
//

import XCTest
import ViewInspector
@testable import PicsumApp

final class PhotoGridAcceptanceTests: XCTestCase, AcceptanceTest {
    @MainActor
    func test_onLaunch_displaysPhotosWhenUserHasConnectivity() async throws {
        let app = try await onLaunch(.online(response))
        
        let photoViews = try await app.photoViews()
        
        XCTAssertEqual(photoViews.count, 3)
        XCTAssertEqual(try photoViews[0].imageData(), imageData0())
        XCTAssertEqual(try photoViews[1].imageData(), imageData1())
        XCTAssertEqual(try photoViews[2].imageData(), imageData2())
    }
    
    @MainActor
    func test_onLaunch_doesNotDisplayPhotosWhenUserHasNoConnectivity() async throws {
        let app = try await onLaunch(.offline)
        
        let photoViews = try await app.photoViews()
        
        XCTAssertTrue(photoViews.isEmpty)
    }
    
    @MainActor
    func test_onLaunch_displaysCachedPhotosWhenCacheExisted() async throws {
        let store = InMemoryImageDataStore.empty
        let onlineApp = try await onLaunch(.online(response), imageDataStore: store)
    
        let onlinePhotoViews = try await onlineApp.photoViews()
        XCTAssertEqual(onlinePhotoViews.count, 3)
        XCTAssertEqual(try onlinePhotoViews[0].imageData(), imageData0())
        XCTAssertEqual(try onlinePhotoViews[1].imageData(), imageData1())
        XCTAssertEqual(try onlinePhotoViews[2].imageData(), imageData2())
        
        let offlineApp = try await onLaunch(.online(responseWithoutImageData), imageDataStore: store)
        let offlinePhotoViews = try await offlineApp.photoViews()
        XCTAssertEqual(offlinePhotoViews.count, 3)
        XCTAssertEqual(try offlinePhotoViews[0].imageData(), imageData0())
        XCTAssertEqual(try offlinePhotoViews[1].imageData(), imageData1())
        XCTAssertEqual(try offlinePhotoViews[2].imageData(), imageData2())
    }
    
    @MainActor
    func test_enteringBackground_invalidatesExpiredImageCache() async throws {
        let store = InMemoryImageDataStore.withExpiredCache
        
        try await enterBackground(with: store)
        
        XCTAssertTrue(store.imageCache.isEmpty)
    }
    
    @MainActor
    func test_enteringBackground_doesNotInvalidateNonExpiredImageCache() async throws {
        let store = InMemoryImageDataStore.withNonExpiredCache
        
        try await enterBackground(with: store)
        
        XCTAssertFalse(store.imageCache.isEmpty)
    }
    
    @MainActor
    func test_selectPhoto_showsPhotoDetail() async throws {
        let app = try await onLaunch(.online(response))
        let firstPhoto = firstPhoto()
        
        try app.select(firstPhoto)
        
        let detailView = try XCTUnwrap(app.detailView())
        XCTAssertEqual(try detailView.authorText(), firstPhoto.author)
    }
    
    // MARK: - Helpers
    
    private typealias PhotosView = PhotoGridView<PhotoGridItemContainer, PhotoDetailContainer>
    
    @MainActor
    private func onLaunch(_ client: HTTPClientStub,
                          imageDataStore: InMemoryImageDataStore = .empty,
                          function: String = #function) async throws -> ContentView {
        let factory = AppComponentsFactory(client: client, imageDataStore: imageDataStore)
        let content = ContentView(factory: factory, store: ContentStore())
        ViewHosting.host(view: content, function: function)
        addTeardownBlock {
            ViewHosting.expel(function: function)
        }
        try await content.completePhotosLoading()
        return content
    }
    
    @MainActor
    private func enterBackground(with store: InMemoryImageDataStore, function: String = #function) async throws {
        let app = try await onLaunch(.offline, imageDataStore: store, function: function)
        try await app.triggerEnteringBackgroundOnChange()
    }
}
