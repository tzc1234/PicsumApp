//
//  PhotoListAcceptanceTests.swift
//  PicsumAppTests
//
//  Created by Tsz-Lung on 04/01/2024.
//

import XCTest
@testable import PicsumApp

final class PhotoListAcceptanceTests: XCTestCase {
    @MainActor
    func test_onLaunch_displaysPhotosWhenUserHasConnectivity() async throws {
        let photos = try await onLaunch(.success(response))
        
        XCTAssertEqual(photos.numberOfRenderedPhotoView(), 2)
        await assertImageData(for: photos, at: 0, asExpected: imageData0())
        await assertImageData(for: photos, at: 1, asExpected: imageData1())
        
        await photos.loadMore()
        
        XCTAssertEqual(photos.numberOfRenderedPhotoView(), 3)
        await assertImageData(for: photos, at: 0, asExpected: imageData0())
        await assertImageData(for: photos, at: 1, asExpected: imageData1())
        await assertImageData(for: photos, at: 2, asExpected: imageData2())
    }
    
    @MainActor
    func test_onLaunch_doesNotDisplayPhotosWhenUserHasNoConnectivity() async throws {
        let photos = try await onLaunch(.failure)
        
        XCTAssertEqual(photos.numberOfRenderedPhotoView(), 0)
    }
    
    @MainActor
    func test_onLaunch_displaysCachedPhotoImagesWhenCacheExisted() async throws {
        let store = InMemoryImageDataStore.empty
        let photosWithoutCachedImage = try await onLaunch(.success(response), imageDataStore: store)
        
        await assertImageData(for: photosWithoutCachedImage, at: 0, asExpected: imageData0())
        await assertImageData(for: photosWithoutCachedImage, at: 1, asExpected: imageData1())
        
        let photosWithCachedImage = try await onLaunch(.success(responseWithoutImageData), imageDataStore: store)
        
        await assertImageData(for: photosWithCachedImage, at: 0, asExpected: imageData0())
        await assertImageData(for: photosWithCachedImage, at: 1, asExpected: imageData1())
    }
    
    @MainActor
    func test_enteringBackground_invalidatesExpiredImageCache() async throws {
        let store = InMemoryImageDataStore.withExpiredCache
        let scene = try await scene(.success(response), imageDataStore: store)
        
        await enterBackground(scene)
        
        XCTAssertTrue(store.imageCache.isEmpty)
    }
    
    // MARK: - Helpers

    @MainActor
    private func scene(_ client: HTTPClientStub,
                       imageDataStore: InMemoryImageDataStore = .empty,
                       file: StaticString = #filePath,
                       line: UInt = #line) async throws -> SceneDelegate {
        let scene = SceneDelegate(client: client, imageDataStore: imageDataStore)
        scene.window = UIWindow()
        scene.configureWindow()
        
        return scene
    }
    
    @MainActor
    private func onLaunch(_ client: HTTPClientStub,
                          imageDataStore: InMemoryImageDataStore = .empty,
                          file: StaticString = #filePath,
                          line: UInt = #line) async throws -> PhotoListViewController {
        let scene = try await scene(client, imageDataStore: imageDataStore, file: file, line: line)
        let nav = try XCTUnwrap(scene.window?.rootViewController as? UINavigationController)
        let vc = try XCTUnwrap(nav.topViewController as? PhotoListViewController)
        vc.simulateAppearance()
        await vc.completePhotosLoading()
        
        return vc
    }
    
    @MainActor
    private func enterBackground(_ scene: SceneDelegate) async {
        scene.sceneWillResignActive(UIApplication.shared.connectedScenes.first!)
        try? await Task.sleep(for: .seconds(0.01)) // Give a little bit time buffer for cache invalidation
    }
    
    private func assertImageData(for photoList: PhotoListViewController, 
                                 at item: Int,
                                 asExpected data: Data,
                                 file: StaticString = #filePath,
                                 line: UInt = #line) async {
        let photoImage = await photoList.renderedImage(at: item)
        XCTAssertEqual(photoImage, data, file: file, line: line)
    }
    
    private func responseWithoutImageData(for url: URL) -> (Data, HTTPURLResponse) {
        (pagesData(for: url) ?? Data(), .ok200Response)
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

extension [[String: Any]] {
    func toData() -> Data {
        try! JSONSerialization.data(withJSONObject: self)
    }
}

private extension Int {
    static var photoDimension: Int { 600 }
}

final class HTTPClientStub: HTTPClient {
    typealias Stub = (URL) throws -> (Data, HTTPURLResponse)
    
    private let stub: Stub
    
    init(stub: @escaping Stub) {
        self.stub = stub
    }
    
    func get(from url: URL) async throws -> (Data, HTTPURLResponse) {
        try stub(url)
    }
    
    static var failure: HTTPClientStub {
        .init { _ in throw anyNSError() }
    }
    
    static func success(_ stub: @escaping Stub) -> HTTPClientStub {
        .init(stub: stub)
    }
}

final class InMemoryImageDataStore: ImageDataStore {
    typealias Cache = (data: Data, timestamp: Date)
    
    private(set) var imageCache: [URL: Cache] = [:]
    
    private init(cache: (data: Data, timestamp: Date, url: URL)? = nil) {
        cache.map { self.imageCache[$0.url] = ($0.data, $0.timestamp) }
    }
    
    func retrieveData(for url: URL) async throws -> Data? {
        imageCache[url]?.data
    }
    
    func insert(data: Data, timestamp: Date, for url: URL) async throws {
        imageCache[url] = (data, timestamp)
    }
    
    func deleteAllData(until date: Date) async throws {
        imageCache = imageCache.filter { _, cache in cache.timestamp > date }
    }
    
    static var empty: InMemoryImageDataStore {
        .init()
    }
    
    static var withExpiredCache: InMemoryImageDataStore {
        .init(cache: (anyData(), Date.distantPast, anyURL()))
    }
}
