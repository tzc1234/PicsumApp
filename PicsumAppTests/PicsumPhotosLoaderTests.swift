//
//  PicsumPhotosLoaderTests.swift
//  PicsumAppTests
//
//  Created by Tsz-Lung on 06/07/2023.
//

import XCTest
@testable import PicsumApp

protocol HTTPClient {
    func get(from url: URL) async throws -> (Data, URLResponse)
}

class PicsumPhotosLoader: PhotosLoader {
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

final class PicsumPhotosLoaderTests: XCTestCase {

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
            XCTAssertEqual(error as? PicsumPhotosLoader.Error, .invaildData)
        }
    }

    // MARK: - Helpers
    
    private func makeSUT(stubs: [ClientSpy.Stub] = [],
                         file: StaticString = #filePath,
                         line: UInt = #line) -> (sut: PicsumPhotosLoader, client: ClientSpy) {
        let client = ClientSpy(stubs: stubs)
        let sut = PicsumPhotosLoader(client: client)
        
        trackForMemoryLeaks(client, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        
        return (sut, client)
    }
    
    private class ClientSpy: HTTPClient {
        typealias Stub = Result<(Data, URLResponse), Error>
        
        private(set) var loggedURLs = [URL]()
        
        private var stubs: [Stub]
        
        init(stubs: [Stub]) {
            self.stubs = stubs
        }
        
        func get(from url: URL) async throws -> (Data, URLResponse) {
            loggedURLs.append(url)
            return try stubs.removeFirst().get()
        }
    }
    
}
