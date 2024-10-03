//
//  PhotoGridAcceptanceTests.swift
//  PicsumAppTests
//
//  Created by Tsz-Lung on 22/01/2024.
//

import XCTest
import ViewInspector
import SwiftUI
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
        let emptyCacheApp = try await onLaunch(.online(response), imageDataStore: store)
    
        let photoViewsWithoutCache = try await emptyCacheApp.photoViews()
        XCTAssertEqual(photoViewsWithoutCache.count, 3)
        XCTAssertEqual(try photoViewsWithoutCache[0].imageData(), imageData0())
        XCTAssertEqual(try photoViewsWithoutCache[1].imageData(), imageData1())
        XCTAssertEqual(try photoViewsWithoutCache[2].imageData(), imageData2())
        
        let cacheExistedApp = try await onLaunch(.online(responseWithoutImageData), imageDataStore: store)
        let photoViewsWithCache = try await cacheExistedApp.photoViews()
        XCTAssertEqual(photoViewsWithCache.count, 3)
        XCTAssertEqual(try photoViewsWithCache[0].imageData(), imageData0())
        XCTAssertEqual(try photoViewsWithCache[1].imageData(), imageData1())
        XCTAssertEqual(try photoViewsWithCache[2].imageData(), imageData2())
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
        
        let detailView = try await app.detailView()
        XCTAssertEqual(try detailView.authorText(), firstPhoto.author)
        XCTAssertEqual(try detailView.imageData(), imageData0())
    }
    
    // MARK: - Helpers
    
    @MainActor
    private func onLaunch(_ client: HTTPClientStub,
                          imageDataStore: InMemoryImageDataStore = .empty,
                          function: String = #function) async throws -> ContentView {
        let factory = AppComponentsFactory(client: client, imageDataStore: imageDataStore)
        let content = ContentView(factory: factory, scenePhase: .active)
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
        try await app.triggerEnteringBackground()
    }
}
