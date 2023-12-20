//
//  RemotePhotosLoaderTests.swift
//  PicsumAppTests
//
//  Created by Tsz-Lung on 06/07/2023.
//

import XCTest
@testable import PicsumApp

final class RemotePhotosLoaderTests: XCTestCase {
    func test_init_doesNotTriggerClient() {
        let (_, client) = makeSUT()
        
        XCTAssertEqual(client.loggedURLs.count, 0)
    }
    
    func test_load_passesCorrectURLToClient() async {
        let (sut, client) = makeSUT(stubs: [.failure(anyNSError())])
        let url = URL(string: "https://a-url.com")!
        
        try? await _ = sut.load(for: url)
        
        XCTAssertEqual(client.loggedURLs, [url])
    }
    
    func test_load_deliversErrorOnClientError() async {
        let (sut, _) = makeSUT(stubs: [.failure(anyNSError())])
        
        await asyncAssertThrowsError(_ = try await sut.load(for: anyURL()))
    }
    
    func test_load_deliversErrorWhenNon200Response() async {
        let simples = [100, 201, 202, 300, 400, 500]
        let stubs = simples.map { ClientSpy.Stub.success((Data(), HTTPURLResponse(statusCode: $0))) }
        let (sut, _) = makeSUT(stubs: stubs)
        
        for statusCode in simples {
            await asyncAssertThrowsError(
                _ = try await sut.load(for: anyURL()),
                "Should not success in statusCode: \(statusCode)") { error in
                    assertInvalidDataError(error)
                }
        }
    }
    
    func test_load_deliversErrorWhen200ResponseButInvalidData() async {
        let invalidData = Data("invalid data".utf8)
        let (sut, _) = makeSUT(stubs: [.success((invalidData, HTTPURLResponse(statusCode: 200)))])
        
        await asyncAssertThrowsError(_ = try await sut.load(for: anyURL())) { error in
            assertInvalidDataError(error)
        }
    }
    
    func test_load_deliversErrorWhen200ResponseButEmptyData() async {
        let emptyData = Data()
        let (sut, _) = makeSUT(stubs: [.success((emptyData, HTTPURLResponse(statusCode: 200)))])
        
        await asyncAssertThrowsError(_ = try await sut.load(for: anyURL())) { error in
            assertInvalidDataError(error)
        }
    }
    
    func test_load_deliversEmptyPhotosWhen200ResponseWithEmptyPhotosData() async throws {
        let emptyPhotos = [Photo]()
        let (sut, _) = makeSUT(stubs: [.success((emptyPhotos.toData(), HTTPURLResponse(statusCode: 200)))])
        
        let photos = try await sut.load(for: anyURL())

        XCTAssertEqual(photos, [])
    }
    
    func test_load_deliversOnePhotoWhen200ResponseWithOnePhotoData() async throws {
        let expectedPhotos = [makePhoto(byIndex: 0)]
        let (sut, _) = makeSUT(stubs: [.success((expectedPhotos.toData(), HTTPURLResponse(statusCode: 200)))])
        
        let photos = try await sut.load(for: anyURL())

        XCTAssertEqual(photos, expectedPhotos)
    }
    
    func test_load_deliversMultiplePhotosWhen200ResponseWithMultiplePhotosData() async throws {
        let expectedPhotos = [makePhoto(byIndex: 0), makePhoto(byIndex: 1), makePhoto(byIndex: 2)]
        let (sut, _) = makeSUT(stubs: [.success((expectedPhotos.toData(), HTTPURLResponse(statusCode: 200)))])
        
        let photos = try await sut.load(for: anyURL())

        XCTAssertEqual(photos, expectedPhotos)
    }

    // MARK: - Helpers
    
    private func makeSUT(stubs: [ClientSpy.Stub] = [],
                         file: StaticString = #filePath,
                         line: UInt = #line) -> (sut: RemotePhotosLoader, client: ClientSpy) {
        let client = ClientSpy(stubs: stubs)
        let sut = RemotePhotosLoader(client: client)
        
        trackForMemoryLeaks(client, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        
        return (sut, client)
    }
    
    private func assertInvalidDataError(_ error: Error, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(error as? PhotosResponseConverter.Error, .invalidData, file: file, line: line)
    }
    
    private func makePhoto(byIndex index: Int) -> Photo {
        Photo(
            id: "\(index)",
            author: "author\(index)",
            width: index,
            height: index,
            webURL: URL(string: "https://web-url-\(index).com")!,
            url: URL(string: "https://url-\(index).com")!)
    }
}

private extension [Photo] {
    func toData() -> Data {
        let json = map { photo in
            [
                "id": photo.id,
                "author": photo.author,
                "width": photo.width,
                "height": photo.height,
                "url": photo.webURL.absoluteString,
                "download_url": photo.url.absoluteString
            ] as [String: Any]
        }
        return try! JSONSerialization.data(withJSONObject: json)
    }
}
