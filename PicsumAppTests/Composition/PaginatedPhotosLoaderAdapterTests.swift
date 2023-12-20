//
//  PaginatedPhotosLoaderAdapterTests.swift
//  PicsumAppTests
//
//  Created by Tsz-Lung on 20/12/2023.
//

import XCTest
@testable import PicsumApp

final class PaginatedPhotosLoaderAdapter {
    init(loader: PhotosLoader) {
        
    }
}

final class PaginatedPhotosLoaderAdapterTests: XCTestCase {
    func test_init_doesNotNotifyLoader() {
        let loader = PhotosLoaderSpy(photoStubs: [])
        let sut = PaginatedPhotosLoaderAdapter(loader: loader)
        
        XCTAssertTrue(loader.loggedPages.isEmpty)
    }
}
