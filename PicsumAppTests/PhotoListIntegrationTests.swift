//
//  PhotoListIntegrationTests.swift
//  PicsumAppTests
//
//  Created by Tsz-Lung on 03/07/2023.
//

import XCTest
import UIKit
@testable import PicsumApp

class PhotoListViewController: UICollectionViewController {
    convenience init(viewModel: PhotoListViewModel) {
        self.init(collectionViewLayout: UICollectionViewFlowLayout())
    }
}

final class PhotoListIntegrationTests: XCTestCase {

    func test_init_noTriggerLoader() {
        let loader = PhotosLoaderSpy(stubs: [])
        let viewModel = PhotoListViewModel(loader: loader)
        _ = PhotoListViewController(viewModel: viewModel)
        
        XCTAssertEqual(loader.loggedPages.count, 0)
    }

}
