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
    func test_onLaunch_displaysPhotosWhenUserHasConnectivityWithEmptyImageCache() async throws {
        let photos = try await onLaunch(.success(makeResponse), imageDataStore: .empty)
        
        XCTAssertEqual(photos.numberOfRenderedPhotoView(), 2)
        await assertImageData(for: photos, at: 0, asExpected: imageData0())
        await assertImageData(for: photos, at: 1, asExpected: imageData1())
    }
    
    // MARK: - Helpers

    @MainActor
    private func onLaunch(_ client: HTTPClientStub,
                          imageDataStore: InMemoryImageDataStore,
                          file: StaticString = #filePath,
                          line: UInt = #line) async throws -> PhotoListViewController {
        let scene = SceneDelegate(client: client, imageDataStore: imageDataStore)
        scene.window = UIWindow()
        scene.configureWindow()
        
        let nav = try XCTUnwrap(scene.window?.rootViewController as? UINavigationController)
        let vc = try XCTUnwrap(nav.topViewController as? PhotoListViewController)
        vc.simulateAppearance()
        await vc.completePhotosLoading()
        
        return vc
    }
    
    private func assertImageData(for photoList: PhotoListViewController, 
                                 at item: Int,
                                 asExpected data: Data,
                                 file: StaticString = #filePath,
                                 line: UInt = #line) async {
        let photoImage = await photoList.renderedImage(at: item)
        XCTAssertEqual(photoImage, data, file: file, line: line)
    }
    
    private func makeResponse(for url: URL) -> (Data, HTTPURLResponse) {
        (makeData(for: url), .ok200Response)
    }
    
    private func makeData(for url: URL) -> Data {
        switch url.path() {
        case "/v2/list" where url.query()?.contains("page=1") == true:
            return page1Data()
            
        case downloadURL(byId: "0").path():
            return imageData0()
            
        case downloadURL(byId: "1").path():
            return imageData1()
            
        default:
            return Data()
        }
    }
    
    private func page1Data() -> Data {
        let json: [[String: Any]] = [
            [
                "id": "0",
                "author": "author0",
                "width": 0,
                "height": 0,
                "url": "https://photo-0.com",
                "download_url": downloadURL(byId: "0").absoluteString
            ],
            [
                "id": "1",
                "author": "author1",
                "width": 1,
                "height": 1,
                "url": "https://photo-1.com",
                "download_url": downloadURL(byId: "1").absoluteString
            ]
        ]
        return try! JSONSerialization.data(withJSONObject: json)
    }
    
    private func downloadURL(byId id: String, width: Int = .photoDimension, height: Int = .photoDimension) -> URL {
        URL(string: "https://picsum.photos/id/\(id)/\(width)/\(height)")!
    }
    
    private func imageData0() -> Data {
        UIImage.makeData(withColor: .red)
    }
    
    private func imageData1() -> Data {
        UIImage.makeData(withColor: .green)
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
    
    private var imageData: [URL: Cache] = [:]
    
    func retrieveData(for url: URL) async throws -> Data? {
        imageData[url]?.data
    }
    
    func insert(data: Data, timestamp: Date, for url: URL) async throws {}
    
    func deleteAllData(until date: Date) async throws {}
    
    static var empty: InMemoryImageDataStore {
        .init()
    }
}
