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
    
    // MARK: - Helpers
    
    private typealias PhotosView = PhotoGridView<PhotoGridItemContainer, EmptyView>
    
    @MainActor
    private func onLaunch(_ client: HTTPClientStub,
                          imageDataStore: InMemoryImageDataStore = .empty,
                          function: String = #function,
                          file: StaticString = #file,
                          line: UInt = #line) async throws -> ContentView {
        let factory = AppComponentsFactory(client: client, imageDataStore: imageDataStore)
        let content = ContentView(factory: factory)
        ViewHosting.host(view: content, function: function)
        addTeardownBlock {
            ViewHosting.expel(function: function)
        }
        try await content.completePhotosLoading()
        return content
    }
}

extension ContentView {
    func completePhotosLoading() async throws {
        let photos = try inspect().find(PhotoGridView<PhotoGridItemContainer, EmptyView>.self).actualView()
        await photos.completePhotosLoading()
    }
    
    typealias PhotoView = InspectableView<ViewType.View<PhotoGridItemContainer>>
    
    func photoViews() async throws -> [PhotoView] {
        let photoViews = try inspect().findAll(PhotoGridItemContainer.self)
        for photoView in photoViews {
            try await photoView.completeImageDataLoading()
        }
        return photoViews
    }
}
