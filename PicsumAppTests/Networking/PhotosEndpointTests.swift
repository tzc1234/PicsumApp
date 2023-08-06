//
//  PhotosEndpointTests.swift
//  PicsumAppTests
//
//  Created by Tsz-Lung on 06/07/2023.
//

import XCTest
@testable import PicsumApp

final class PhotosEndpointTests: XCTestCase {

    func test_get_deliversCorrectURL() {
        let url = PhotosEndpoint.get(page: 1).url.absoluteString
        
        XCTAssertTrue(url.contains("https://picsum.photos/v2/list?"))
        XCTAssertTrue(url.contains("page=1"))
    }

}
