//
//  PhotoGridIntegrationTests.swift
//  PicsumAppTests
//
//  Created by Tsz-Lung on 15/01/2024.
//

import XCTest
import ViewInspector
@testable import PicsumApp

final class PhotoGridIntegrationTests: XCTestCase {
    @MainActor
    func test_init_doesNotTriggerLoader() async {
        let (_, loader) = makeSUT()
        
        XCTAssertTrue(loader.loggedURLs.isEmpty)
        
        ViewHosting.expel()
    }
    
    @MainActor
    func test_loadPhotos_requestPhotosFromLoader() async {
        let (sut, loader) = makeSUT(photoStubs: [emptySuccessPhotos(), emptySuccessPhotos()])
        
        await sut.completePhotosLoading()
        XCTAssertEqual(loader.loggedURLs.count, 1, "Expect 1 request once view rendered")
        
        sut.simulateUserInitiateReload()
        await sut.completePhotosLoading()
        XCTAssertEqual(loader.loggedURLs.count, 2, "Expect 2 requests after user initiate reload")
        
        ViewHosting.expel()
    }
    
    @MainActor
    func test_loadPhotos_cancelsPreviousUnfinishedPhotosLoadingBeforeNewPhotosLoading() async throws {
        let (sut, _) = makeSUT()
        
        let previousPhotosLoadingTask = try XCTUnwrap(sut.photosLoadingTask)
        XCTAssertFalse(previousPhotosLoadingTask.isCancelled, "Expect previous task is not cancelled just after view rendered")
        
        sut.simulateUserInitiateReload()
        let newPhotosLoadingTask = try XCTUnwrap(sut.photosLoadingTask)
        
        XCTAssertTrue(previousPhotosLoadingTask.isCancelled, "Expect previous unfinished task is cancelled after user initiate new photos loading")
        XCTAssertFalse(newPhotosLoadingTask.isCancelled, "Expect new task is not cancelled")
        
        ViewHosting.expel()
    }
    
    // MARK: - Helpers
    
    private func makeSUT(photoStubs: [PhotosLoaderSpy.PhotosResult] = [],
                         dataStubs: [PhotosLoaderSpy.DataResult] = [],
                         function: String = #function,
                         file: StaticString = #file,
                         line: UInt = #line) -> (sut: PhotoGridView, loader: PhotosLoaderSpy) {
        let loader = PhotosLoaderSpy(photoStubs: photoStubs, dataStubs: dataStubs)
        let sut = PhotoGridComposer.composeWith(photosLoader: loader)
        ViewHosting.host(view: sut, function: function)
        trackForMemoryLeaks(loader, file: file, line: line)
        return (sut, loader)
    }
    
    private func emptySuccessPhotos() -> PhotosLoaderSpy.PhotosResult {
        .success([])
    }
}

extension PhotoGridView {
    func completePhotosLoading() async {
        await delegate.loadPhotosTask?.value
    }
    
    func simulateUserInitiateReload() {
        // ViewInspector does not support SwiftUI refreshable yet, therefore directly trigger the loadPhotos()
        delegate.loadPhotos()
    }
    
    var photosLoadingTask: Task<Void, Never>? {
        delegate.loadPhotosTask
    }
}
