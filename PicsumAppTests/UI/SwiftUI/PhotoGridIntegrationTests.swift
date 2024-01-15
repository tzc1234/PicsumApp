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
    }
    
    @MainActor
    func test_loadPhotos_requestPhotosFromLoader() async {
        let (sut, loader) = makeSUT(photoStubs: [emptySuccessPhotos(), emptySuccessPhotos()])
        
        await sut.completePhotosLoading()
        XCTAssertEqual(loader.loggedURLs.count, 1, "Expect 1 request once view rendered")
        
        sut.simulateUserInitiateReload()
        await sut.completePhotosLoading()
        XCTAssertEqual(loader.loggedURLs.count, 2, "Expect 2 requests after user initiate reload")
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
    }
    
    // ViewInspector does not support extracting loading indicator from refreshable.
    // Not sure should I add this test.
    @MainActor
    func test_loadingIndicator_showsLoadingIndicatorWhileLoadingPhotos() async {
        let (sut, _) = makeSUT()
        
        XCTAssertTrue(sut.isShowingLoadingIndicator, "Expect showing loading indicator after view rendered")
        
        await sut.completePhotosLoading()
        
        XCTAssertFalse(sut.isShowingLoadingIndicator, "Expect not showing loading indicator after photos loading completed")
        
        sut.simulateUserInitiateReload()
        
        XCTAssertTrue(sut.isShowingLoadingIndicator, "Expect showing loading indicator after user initiated reload")
        
        await sut.completePhotosLoading()
        
        XCTAssertFalse(sut.isShowingLoadingIndicator, "Expect not showing loading indicator after user initiated reload completed")
    }
    
    @MainActor
    func test_loadPhotosCompletion_rendersPhotoViewsSuccessfully() async throws {
        let photo0 = makePhoto(id: "0", author: "author0")
        let photo1 = makePhoto(id: "1", author: "author1")
        let photo2 = makePhoto(id: "2", author: "author2")
        let (sut, _) = makeSUT(photoStubs: [.success([photo0, photo1]), .success([photo0, photo1, photo2])])
        
        await sut.completePhotosLoading()
        
        try assertThat(sut, isRendering: [photo0, photo1])
        
        sut.simulateUserInitiateReload()
        await sut.completePhotosLoading()
        
        try assertThat(sut, isRendering: [photo0, photo1, photo2])
    }
    
    @MainActor
    func test_loadPhotosCompletion_doesNotAlterCurrentRenderedPhotoViewsOnLoaderError() async throws {
        let photo0 = makePhoto(id: "0", author: "author0")
        let photo1 = makePhoto(id: "1", author: "author1")
        let (sut, _) = makeSUT(photoStubs: [.success([photo0, photo1]), anyFailure()])
        
        await sut.completePhotosLoading()
        
        try assertThat(sut, isRendering: [photo0, photo1])
        
        sut.simulateUserInitiateReload()
        await sut.completePhotosLoading()
        
        try assertThat(sut, isRendering: [photo0, photo1])
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
        trackMemoryLeaks(for: loader, function: function, file: file, line: line)
        return (sut, loader)
    }
    
    private func trackMemoryLeaks(for instance: AnyObject,
                                  function: String = #function,
                                  file: StaticString = #file,
                                  line: UInt = #line) {
        addTeardownBlock { [weak instance] in
            await MainActor.run { ViewHosting.expel(function: function) }
            try? await Task.sleep(for: .seconds(0.01)) // Buffer time for instance releasing.
            
            XCTAssertNil(
                instance,
                "Instance should have been deallocated. Potential memory leak.",
                file: file,
                line: line
            )
        }
    }
    
    private func assertThat(_ sut: PhotoGridView, 
                            isRendering photos: [Photo],
                            file: StaticString = #file, 
                            line: UInt = #line) throws {
        let viewCount = try sut.numberOfRenderedViews()
        guard photos.count == viewCount else {
            XCTFail("Expect \(photos.count) photo views, got \(viewCount) instead", file: file, line: line)
            return
        }
        
        for tuple in photos.enumerated() {
            try assertThat(sut, hasViewConfigureFor: tuple.element, at: tuple.offset, file: file, line: line)
        }
    }
    
    private func assertThat(_ sut: PhotoGridView, 
                            hasViewConfigureFor photo: Photo,
                            at index: Int,
                            file: StaticString = #file, 
                            line: UInt = #line) throws {
        XCTAssertEqual(
            try sut.authorText(at: index),
            photo.author,
            "Expect author: \(photo.author) for index \(index)",
            file: file,
            line: line
        )
    }
    
    private func emptySuccessPhotos() -> PhotosLoaderSpy.PhotosResult {
        .success([])
    }
    
    private func anyFailure() -> PhotosLoaderSpy.PhotosResult {
        .failure(anyNSError())
    }
}

extension PhotoGridView {
    func completePhotosLoading() async {
        await store.delegate.loadPhotosTask?.value
    }
    
    func simulateUserInitiateReload() {
        // ViewInspector does not support SwiftUI refreshable yet, therefore directly trigger the loadPhotos()
        store.loadPhotos()
    }
    
    var photosLoadingTask: Task<Void, Never>? {
        store.delegate.loadPhotosTask
    }
    
    var isShowingLoadingIndicator: Bool {
        store.isLoading
    }
    
    func renderedViews() throws -> [InspectableView<ViewType.View<PhotoGridItem>>] {
        try inspect().findAll(PhotoGridItem.self)
    }
    
    func numberOfRenderedViews() throws -> Int {
        try renderedViews().count
    }
    
    func authorText(at index: Int) throws -> String {
        try renderedViews()[index].authorText()
    }
}

extension InspectableView<ViewType.View<PhotoGridItem>> {
    func authorText() throws -> String {
        try find(viewWithAccessibilityIdentifier: "photo-grid-item-author")
            .text()
            .string()
    }
}
