//
//  LoadCachedImageDataUseCaseTests.swift
//  PicsumAppTests
//
//  Created by Tsz-Lung on 10/07/2023.
//

import XCTest
@testable import PicsumApp

final class LoadCachedImageDataUseCaseTests: XCTestCase {

    class LocalImageDataLoader {
        init(store: ImageDataStoreSpy) {
            
        }
    }
    
    func test_init_noTriggerStore() {
        let store = ImageDataStoreSpy()
        _ = LocalImageDataLoader(store: store)
        
        XCTAssertEqual(store.messages.count, 0)
    }
    
    // MARK: - Helpers
    
    class ImageDataStoreSpy {
        private(set) var messages = [Any]()
    }
    
}
