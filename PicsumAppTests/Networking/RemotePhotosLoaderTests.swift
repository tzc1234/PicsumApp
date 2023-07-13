//
//  RemotePhotosLoaderTests.swift
//  PicsumAppTests
//
//  Created by Tsz-Lung on 06/07/2023.
//

import XCTest
@testable import PicsumApp

final class RemotePhotosLoaderTests: XCTestCase {

    func test_init_noTriggerClient() {
        let (_, client) = makeSUT()
        
        XCTAssertEqual(client.loggedURLs.count, 0)
    }
    
    func test_load_passesCorrectURLToClient() async {
        let (sut, client) = makeSUT(stubs: [.failure(anyNSError())])
        let page = 99
        
        try? await _ = sut.load(page: page)
        
        XCTAssertEqual(client.loggedURLs, [PhotosEndpoint.get(page: page).url])
    }
    
    func test_load_deliversErrorOnClientError() async {
        let (sut, _) = makeSUT(stubs: [.failure(anyNSError())])
        
        do {
            try await _ = sut.load(page: 1)
            XCTFail("Should not success")
        } catch {
            assertInvalidDataError(error)
        }
    }
    
    func test_load_deliversErrorWhenNon200Response() async {
        let simples = [100, 201, 202, 300, 400, 500]
        let stubs = simples.map { ClientSpy.Stub.success((Data(), HTTPURLResponse(statusCode: $0))) }
        let (sut, _) = makeSUT(stubs: stubs)
        
        for statusCode in simples {
            do {
                try await _ = sut.load(page: 1)
                XCTFail("Should not success in statusCode: \(statusCode)")
            } catch {
                assertInvalidDataError(error)
            }
        }
    }
    
    func test_load_deliversErrorWhen200ResponseButInvalidData() async {
        let invalidData = Data("invalid data".utf8)
        let (sut, _) = makeSUT(stubs: [.success((invalidData, HTTPURLResponse(statusCode: 200)))])
        
        do {
            try await _ = sut.load(page: 1)
            XCTFail("Should not success")
        } catch {
            assertInvalidDataError(error)
        }
    }
    
    func test_load_deliversErrorWhen200ResponseButEmptyData() async {
        let emptyData = Data()
        let (sut, _) = makeSUT(stubs: [.success((emptyData, HTTPURLResponse(statusCode: 200)))])
        
        do {
            _ = try await sut.load(page: 1)
            XCTFail("Should not success")
        } catch {
            assertInvalidDataError(error)
        }
    }
    
    func test_load_deliversEmptyPhotosWhen200ResponseWithEmptyPhotosData() async throws {
        let emptyPhotos = [Photo]()
        let (sut, _) = makeSUT(stubs: [.success((emptyPhotos.toData(), HTTPURLResponse(statusCode: 200)))])
        
        let photos = try await sut.load(page: 1)

        XCTAssertEqual(photos, [])
    }
    
    func test_load_deliversOnePhotoWhen200ResponseWithOnePhotoData() async throws {
        let expectedPhotos = [
            Photo(id: "0", author: "author", width: 0, height: 0, webURL: URL(string: "https://web-url.com")!, url: anyURL())
        ]
        let (sut, _) = makeSUT(stubs: [.success((expectedPhotos.toData(), HTTPURLResponse(statusCode: 200)))])
        
        let photos = try await sut.load(page: 1)

        XCTAssertEqual(photos, expectedPhotos)
    }
    
    func test_load_deliversMultiplePhotosWhen200ResponseWithMultiplePhotosData() async throws {
        let expectedPhotos = [
            Photo(id: "0", author: "author0", width: 0, height: 0, webURL: URL(string: "https://web-url-0.com")!, url: URL(string: "https://url-0.com")!),
            Photo(id: "1", author: "author1", width: 1, height: 1, webURL: URL(string: "https://web-url-1.com")!, url: URL(string: "https://url-1.com")!),
            Photo(id: "2", author: "author2", width: 2, height: 2, webURL: URL(string: "https://web-url-2.com")!, url: URL(string: "https://url-2.com")!)
        ]
        let (sut, _) = makeSUT(stubs: [.success((expectedPhotos.toData(), HTTPURLResponse(statusCode: 200)))])
        
        let photos = try await sut.load(page: 1)

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