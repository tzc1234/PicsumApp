//
//  RemoteImageDataLoaderTests.swift
//  PicsumAppTests
//
//  Created by Tsz-Lung on 06/07/2023.
//

import XCTest
@testable import PicsumApp

class RemoteImageDataLoader: ImageDataLoader {
    private let client: HTTPClient
    
    init(client: HTTPClient) {
        self.client = client
    }
    
    func loadImageData(from url: URL) async throws -> Data {
        _ = try? await client.get(from: url)
        return Data()
    }
}

final class RemoteImageDataLoaderTests: XCTestCase {

    func test_init_noTriggerClient() {
        let (_, client) = makeSUT()
        
        XCTAssertEqual(client.loggedURLs.count, 0)
    }
    
    func test_loadImageData_passesCorrectURLToClient() async throws {
        let (sut, client) = makeSUT(stubs: [.failure(anyNSError())])
        let url = anyURL()
        
        _ = try await sut.loadImageData(from: url)
        
        XCTAssertEqual(client.loggedURLs, [url])
    }

    // MARK: - Helpers
    
    private func makeSUT(stubs: [ClientSpy.Stub] = [],
                         file: StaticString = #filePath,
                         line: UInt = #line) -> (sut: RemoteImageDataLoader, client: ClientSpy) {
        let client = ClientSpy(stubs: stubs)
        let sut = RemoteImageDataLoader(client: client)
        
        trackForMemoryLeaks(client, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        
        return (sut, client)
    }
}
