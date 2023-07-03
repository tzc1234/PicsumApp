//
//  PhotoListViewModelTests.swift
//  PicsumAppTests
//
//  Created by Tsz-Lung on 03/07/2023.
//

import XCTest
@testable import PicsumApp

protocol PhotosLoader {
    
}

class PhotoListViewModel {
    init(loader: PhotosLoader) {
        
    }
}

final class PhotoListViewModelTests: XCTestCase {
    
    func test_init_withoutTriggerLoader() {
        let loader = LoaderSpy()
        _ = PhotoListViewModel(loader: loader)
        
        XCTAssertEqual(loader.messages.count, 0)
    }

    // MARK: - Helpers
    
    private class LoaderSpy: PhotosLoader {
        private(set) var messages = [Any]()
    }
    
}
