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
    private lazy var refreshControl = {
        let refresh = UIRefreshControl()
        refresh.addTarget(self, action: #selector(reload), for: .valueChanged)
        return refresh
    }()
    
    private(set) var task: Task<Void, Never>?
    private var viewModel: PhotoListViewModel?
    
    convenience init(viewModel: PhotoListViewModel) {
        self.init(collectionViewLayout: UICollectionViewFlowLayout())
        self.title = PhotoListViewModel.title
        self.viewModel = viewModel
    }
    
    override func viewDidLoad() {
        collectionView.refreshControl = refreshControl
        reload()
    }
    
    @objc private func reload() {
        task = Task {
            await viewModel?.load()
        }
    }
}

final class PhotoListIntegrationTests: XCTestCase {
    
    func test_photosList_hasTitle() {
        let (sut, _) = makeSUT()
        
        XCTAssertEqual(sut.title, PhotoListViewModel.title)
    }
    
    func test_init_noTriggerLoader() {
        let (_, loader) = makeSUT()
        
        XCTAssertEqual(loader.loggedPages.count, 0)
    }
    
    @MainActor
    func test_loadPhotosAction_requestPhotosFromLoader() async {
        let (sut, loader) = makeSUT(stubs: [.success([]), .success([]), .success([])])
        
        XCTAssertEqual(loader.loggedPages.count, 0)
        
        sut.loadViewIfNeeded()
        await sut.task?.value
        XCTAssertEqual(loader.loggedPages.count, 1, "Expect one request once the view is loaded")
        
        sut.simulateUserInitiatedReload()
        await sut.task?.value
        XCTAssertEqual(loader.loggedPages.count, 2, "Expect another request after user initiated a reload")

        sut.simulateUserInitiatedReload()
        await sut.task?.value
        XCTAssertEqual(loader.loggedPages.count, 3, "Expect yet another request after user initiated another reload")
    }

    // MARK: - Helpers
    
    private typealias Result = PhotosLoaderSpy.Result
    
    private func makeSUT(stubs: [Result] = [],
                         file: StaticString = #file,
                         line: UInt = #line) -> (sut: PhotoListViewController, loader: PhotosLoaderSpy) {
        let loader = PhotosLoaderSpy(stubs: stubs)
        let viewModel = PhotoListViewModel(loader: loader)
        let sut = PhotoListViewController(viewModel: viewModel)
        
        trackForMemoryLeaks(loader, file: file, line: line)
        trackForMemoryLeaks(viewModel, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        
        return (sut, loader)
    }
    
}

extension PhotoListViewController {
    func simulateUserInitiatedReload() {
        refreshControl.simulatePullToRefresh()
    }
}
