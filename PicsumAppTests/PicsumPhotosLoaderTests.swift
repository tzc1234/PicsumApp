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

class PicsumPhotosLoader {
    init(client: HTTPClient) {
        
    }
}

final class PicsumPhotosLoaderTests: XCTestCase {

    func test_init_noTriggerClient() {
        let client = ClientSpy()
        let _ = PicsumPhotosLoader(client: client)
        
        XCTAssertEqual(client.loggedURLs.count, 0)
    }

    // MARK: - Helpers
    
    private class ClientSpy: HTTPClient {
        private(set) var loggedURLs = [URL]()
        
        func get(from url: URL) async throws -> (Data, URLResponse) {
            fatalError()
        }
    }
    
}
