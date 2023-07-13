//
//  ImageDataLoaderCacheDecoratorTests.swift
//  PicsumAppTests
//
//  Created by Tsz-Lung on 13/07/2023.
//

import XCTest
@testable import PicsumApp

class ImageDataLoaderCacheDecorator {
    init(loader: ImageDataLoader) {
        
    }
}

final class ImageDataLoaderCacheDecoratorTests: XCTestCase {

    func test_init_noTriggerOnLoader() {
        let loader = RemoteImageDataLoaderSpy(stubs: [])
        _ = ImageDataLoaderCacheDecorator(loader: loader)
        
        XCTAssertEqual(loader.loggedURLs.count, 0)
    }

}
