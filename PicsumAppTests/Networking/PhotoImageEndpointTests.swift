//
//  PhotoImageEndpointTests.swift
//  PicsumAppTests
//
//  Created by Tsz-Lung on 07/07/2023.
//

import XCTest
@testable import PicsumApp

final class PhotoImageEndpointTests: XCTestCase {

    func test_get_deliversCorrectURL() {
        let url = PhotoImageEndpoint.get(id: "99", width: 500, height: 500).url.absoluteString
        
        XCTAssertEqual(url, "https://picsum.photos/id/99/500/500")
    }

}
