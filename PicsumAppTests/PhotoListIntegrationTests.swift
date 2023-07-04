//
//  PhotoListIntegrationTests.swift
//  PicsumAppTests
//
//  Created by Tsz-Lung on 03/07/2023.
//

import XCTest
import UIKit
@testable import PicsumApp

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
        await sut.reloadPhotosTask?.value
        XCTAssertEqual(loader.loggedPages.count, 1, "Expect one request once the view is loaded")
        
        sut.simulateUserInitiatedReload()
        await sut.reloadPhotosTask?.value
        XCTAssertEqual(loader.loggedPages.count, 2, "Expect another request after user initiated a reload")

        sut.simulateUserInitiatedReload()
        await sut.reloadPhotosTask?.value
        XCTAssertEqual(loader.loggedPages.count, 3, "Expect yet another request after user initiated another reload")
    }
    
    @MainActor
    func test_loadPhotosAction_cancelPreviousUnfinishedTaskBeforeNewRequest() async throws {
        let (sut, _) = makeSUT(stubs: [.success([]), .success([])])
        
        sut.loadViewIfNeeded()
        let previousTask = try XCTUnwrap(sut.reloadPhotosTask)
        
        XCTAssertEqual(previousTask.isCancelled, false)
        
        sut.simulateUserInitiatedReload()
        await sut.reloadPhotosTask?.value
        
        XCTAssertEqual(previousTask.isCancelled, true)
    }
    
    @MainActor
    func test_loadingPhotosIndicator_isVisiableWhileLoadingPhotos() async {
        let (sut, loader) = makeSUT(stubs: [.success([]), .success([])])

        var indicatorLoadingStates = [Bool]()
        loader.beforeLoad = { [weak sut] in
            indicatorLoadingStates.append(sut?.isShowingLoadingIndicator == true)
        }
        sut.loadViewIfNeeded()
        
        await sut.reloadPhotosTask?.value
        XCTAssertEqual(indicatorLoadingStates, [true], "Expect showing loading indicator once the view is loaded")
        XCTAssertFalse(sut.isShowingLoadingIndicator, "Expect not showing loading indicator once the photos loading finished")

        sut.simulateUserInitiatedReload()

        await sut.reloadPhotosTask?.value
        XCTAssertEqual(indicatorLoadingStates, [true, true], "Expect showing loading indicator again after user initiated a reload")
        XCTAssertFalse(sut.isShowingLoadingIndicator, "Expect not showing loading indicator agin after user initiated reload finished")
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
    
    var isShowingLoadingIndicator: Bool {
        refreshControl.isRefreshing
    }
}
