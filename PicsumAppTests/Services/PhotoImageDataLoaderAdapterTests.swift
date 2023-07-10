//
//  PhotoImageDataLoaderAdapterTests.swift
//  PicsumAppTests
//
//  Created by Tsz-Lung on 10/07/2023.
//

import XCTest
@testable import PicsumApp

class PhotoImageDataLoaderAdapter {
    init(imageDataLoader: ImageDataLoader) {}
}

final class PhotoImageDataLoaderAdapterTests: XCTestCase {

    func test_init_noTriggerRemoteImageDataLoader() {
        let loader = RemoteImageDataLoaderSpy()
        _ = PhotoImageDataLoaderAdapter(imageDataLoader: loader)
        
        XCTAssertEqual(loader.messages.count, 0)
    }

    // MARK: - Helpers
    
    private class RemoteImageDataLoaderSpy: ImageDataLoader {
        private(set) var messages = [Any]()
        
        func loadImageData(for url: URL) async throws -> Data {
            throw anyNSError()
        }
    }
    
}
