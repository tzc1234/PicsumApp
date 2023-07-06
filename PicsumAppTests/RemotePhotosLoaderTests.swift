//
//  RemotePhotosLoaderTests.swift
//  PicsumAppTests
//
//  Created by Tsz-Lung on 06/07/2023.
//

import XCTest
@testable import PicsumApp

protocol HTTPClient {
    func get(from url: URL) async throws -> (Data, HTTPURLResponse)
}

class RemotePhotosLoader: PhotosLoader {
    private let client: HTTPClient
    
    init(client: HTTPClient) {
        self.client = client
    }
    
    enum Error: Swift.Error {
        case invaildData
    }
    
    func load(page: Int) async throws -> [PicsumApp.Photo] {
        try? await _ = client.get(from: PhotosEndpoint.get(page: page).url)
        throw Error.invaildData
    }
}

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
            assertInvaildDataError(error)
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
                assertInvaildDataError(error)
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
            assertInvaildDataError(error)
        }
    }
    
    func test_load_deliversErrorWhen200ResponseButEmptyData() async {
        let emptyData = Data()
        let (sut, _) = makeSUT(stubs: [.success((emptyData, HTTPURLResponse(statusCode: 200)))])
        
        do {
            try await _ = sut.load(page: 1)
            XCTFail("Should not success")
        } catch {
            assertInvaildDataError(error)
        }
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
    
    private func assertInvaildDataError(_ error: Error, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(error as? RemotePhotosLoader.Error, .invaildData, file: file, line: line)
    }
    
    private class ClientSpy: HTTPClient {
        typealias Stub = Result<(Data, HTTPURLResponse), Error>
        
        private(set) var loggedURLs = [URL]()
        
        private var stubs: [Stub]
        
        init(stubs: [Stub]) {
            self.stubs = stubs
        }
        
        func get(from url: URL) async throws -> (Data, HTTPURLResponse) {
            loggedURLs.append(url)
            return try stubs.removeFirst().get()
        }
    }
    
}

extension HTTPURLResponse {
    convenience init(statusCode: Int) {
        self.init(url: URL(string: "https://any-url.com")!, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
    }
}
