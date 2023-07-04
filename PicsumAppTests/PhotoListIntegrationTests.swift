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
    
    @MainActor
    func test_loadPhotosCompletion_renderSuccessfullyLoadedPhotos() async throws {
        let photo0 = makePhoto(id: "0", author: "author0")
        let photo1 = makePhoto(id: "1", author: "author1")
        let photo2 = makePhoto(id: "2", author: "author2")
        let (sut, _) = makeSUT(stubs: [.success([photo0]), .success([photo0, photo1, photo2])])
        
        sut.loadViewIfNeeded()
        
        assertThat(sut, isRendering: [])
        
        await sut.reloadPhotosTask?.value
        
        assertThat(sut, isRendering: [photo0])
        
        sut.simulateUserInitiatedReload()
        await sut.reloadPhotosTask?.value
        
        assertThat(sut, isRendering: [photo0, photo1, photo2])
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
    
    private func assertThat(_ sut: PhotoListViewController, isRendering photos: [Photo],
                            file: StaticString = #file, line: UInt = #line) {
        guard photos.count == sut.numberOfRenderedPhotoView() else {
            XCTFail("Expect \(photos.count) photo views, got \(sut.numberOfRenderedPhotoView()) instead", file: file, line: line)
            return
        }
        
        photos.enumerated().forEach { index, photo in
            assertThat(sut, hasViewConfigureFor: photo, at: index, file: file, line: line)
        }
    }
    
    private func assertThat(_ sut: PhotoListViewController, hasViewConfigureFor photo: Photo, at index: Int,
                            file: StaticString = #file, line: UInt = #line) {
        guard let view = sut.photoView(at: index) else {
            XCTFail("Expect a photo view at index \(index)", file: file, line: line)
            return
        }
        
        XCTAssertEqual(view.authorText, photo.author, "Expect author: \(photo.author) for index \(index)", file: file, line: line)
    }
    
}

extension PhotoListViewController {
    public override func loadViewIfNeeded() {
        super.loadViewIfNeeded()
        
        collectionView.frame = CGRect(x: 0, y: 0, width: 1, height: 1)
    }
    
    func simulateUserInitiatedReload() {
        refreshControl.simulatePullToRefresh()
    }
    
    var isShowingLoadingIndicator: Bool {
        refreshControl.isRefreshing
    }
    
    func numberOfRenderedPhotoView() -> Int {
        collectionView.numberOfSections > photoViewSection ? collectionView.numberOfItems(inSection: photoViewSection) : 0
    }
    
    func photoView(at row: Int) -> PhotoListCell? {
        let ds = collectionView.dataSource
        let indexPath = IndexPath(row: row, section: photoViewSection)
        return ds?.collectionView(collectionView, cellForItemAt: indexPath) as? PhotoListCell
    }
    
    private var photoViewSection: Int {
        0
    }
}

extension PhotoListCell {
    var authorText: String? {
        authorLabel.text
    }
}
