//
//  RemoteImageDataLoaderTests.swift
//  PicsumAppTests
//
//  Created by Tsz-Lung on 06/07/2023.
//

import XCTest
@testable import PicsumApp

class RemoteImageDataLoader {
    init(client: HTTPClient) {
        
    }
}

final class RemoteImageDataLoaderTests: XCTestCase {

    func test_init_noTriggerClient() {
        let client = ClientSpy(stubs: [])
        let _ = RemoteImageDataLoader(client: client)
        
        XCTAssertEqual(client.loggedURLs.count, 0)
    }

}
