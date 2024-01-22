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

final class PhotoGridAcceptanceTests: XCTestCase {
    @MainActor
    func test_onLaunch_displaysPhotosWhenUserHasConnectivity() async throws {
        let app = try await onLaunch(.online(response))
        
        let photoViews = try await app.photoViews()
        XCTAssertEqual(photoViews.count, 3)
        XCTAssertEqual(try photoViews[0].imageData(), imageData0())
        XCTAssertEqual(try photoViews[1].imageData(), imageData1())
        XCTAssertEqual(try photoViews[2].imageData(), imageData2())
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
        try await content.completeAllPhotosLoading()
        return content
    }
    
    private func response(for url: URL) -> (Data, HTTPURLResponse) {
        let data = pagesData(for: url) ?? imagesData(for: url) ?? Data()
        return (data, .ok200Response)
    }
    
    private func pagesData(for url: URL) -> Data? {
        switch url.path() {
        case "/v2/list" where url.query()?.contains("page=1") == true:
            return page1Data()
        case "/v2/list" where url.query()?.contains("page=2") == true:
            return page2Data()
        default:
            return nil
        }
    }
    
    private func imagesData(for url: URL) -> Data? {
        switch url.path() {
        case downloadURLFor(id: "0").path():
            return imageData0()
        case downloadURLFor(id: "1").path():
            return imageData1()
        case downloadURLFor(id: "2").path():
            return imageData2()
        default:
            return nil
        }
    }
    
    private func page1Data() -> Data {
        [
            [
                "id": "0",
                "author": "author0",
                "width": 0,
                "height": 0,
                "url": "https://photo-0.com",
                "download_url": downloadURLFor(id: "0").absoluteString
            ],
            [
                "id": "1",
                "author": "author1",
                "width": 1,
                "height": 1,
                "url": "https://photo-1.com",
                "download_url": downloadURLFor(id: "1").absoluteString
            ]
        ].toData()
    }
    
    private func page2Data() -> Data {
        [
            [
                "id": "2",
                "author": "author2",
                "width": 2,
                "height": 2,
                "url": "https://photo-2.com",
                "download_url": downloadURLFor(id: "2").absoluteString
            ]
        ].toData()
    }
    
    private func downloadURLFor(id: String, width: Int = .photoDimension, height: Int = .photoDimension) -> URL {
        URL(string: "https://picsum.photos/id/\(id)/\(width)/\(height)")!
    }
    
    private func imageData0() -> Data {
        UIImage.makeData(withColor: .red)
    }
    
    private func imageData1() -> Data {
        UIImage.makeData(withColor: .green)
    }
    
    private func imageData2() -> Data {
        UIImage.makeData(withColor: .blue)
    }
}

extension ContentView {
    func completeAllPhotosLoading() async throws {
        let photos = try inspect().find(PhotoGridView<PhotoGridItemContainer, EmptyView>.self).actualView()
        await photos.completePhotosLoading()
        await photos.completeLoadMorePhotos()
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
