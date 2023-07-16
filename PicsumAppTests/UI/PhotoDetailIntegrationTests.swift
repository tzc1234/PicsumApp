//
//  PhotoDetailIntegrationTests.swift
//  PicsumAppTests
//
//  Created by Tsz-Lung on 16/07/2023.
//

import XCTest
@testable import PicsumApp

class PhotoDetailViewController: UIViewController {
    init() {
        super.init(nibName: nil, bundle: nil)
        self.title = "Photo"
    }
    
    required init?(coder: NSCoder) {
        nil
    }
}

final class PhotoDetailIntegrationTests: XCTestCase {

    func test_init_hasTitle() {
        let sut = PhotoDetailViewController()
        
        XCTAssertEqual(sut.title, "Photo")
    }

}
