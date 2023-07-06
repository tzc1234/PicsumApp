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
    enum Error: Swift.Error {
        case invaildData
    }
    
    init(client: HTTPClient) {
        
    }
    
    func load(page: Int) async throws -> [PicsumApp.Photo] {
        throw Error.invaildData
    }
}

final class PicsumPhotosLoaderTests: XCTestCase {

    func test_init_noTriggerClient() {
        let (_, client) = makeSUT()
        
        XCTAssertEqual(client.loggedURLs.count, 0)
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
    
    private func makeSUT(stubs: [Result<(Data, URLResponse), Error>] = [],
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
            fatalError()
        }
    }
    
}
