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
    
    // MARK: - Photo view tests
    
    @MainActor
    func test_photoView_loadsImageWhenVisible() async throws {
        let photo0 = makePhoto(id: "0")
        let photo1 = makePhoto(id: "1")
        let (sut, loader) = makeSUT(
            photoStubs: [.success([photo0, photo1])],
            dataStubs: [anySuccessData(), anySuccessData()]
        )
        
        XCTAssertEqual(loader.loggedPhotoIDSet, [], "Expect no photo data request just after view is rendered")
        
        await sut.completePhotosLoading()
        try await sut.completeImageDataLoading(at: 0)
        
        XCTAssertEqual(loader.loggedPhotoIDSet, [photo0.id, photo1.id], "Expect 2 photo data requests after 2 photo views are rendered")
    }
    
    @MainActor
    func test_photoView_loadsImageAgainWhileInvisibleViewIsVisibleAgain() async throws {
        let photo0 = makePhoto(id: "0")
        let (sut, loader) = makeSUT(photoStubs: [.success([photo0])], dataStubs: [anySuccessData(), anySuccessData()])
        
        await sut.completePhotosLoading()
        
        try await sut.completeImageDataLoading(at: 0)
        XCTAssertEqual(loader.loggedPhotoIDs, [photo0.id], "Expect 1 photo data request after photo view is visible")
        
        try sut.simulatePhotoViewInvisible(at: 0)
        XCTAssertEqual(loader.loggedPhotoIDs, [photo0.id], "Expect no photo data requests changes after photo view is invisible")
        
        try sut.simulatePhotoViewVisible(at: 0)
        try await sut.completeImageDataLoading(at: 0)
        XCTAssertEqual(loader.loggedPhotoIDs, [photo0.id, photo0.id], "Expect 2 photo data requests after photo view is visible again")
    }
    
    @MainActor
    func test_photoViewLoadingIndicator_showsLoadingIndicatorWhileLoadingImage() async throws {
        let photo0 = makePhoto(id: "0")
        let photo1 = makePhoto(id: "1")
        let (sut, _) = makeSUT(
            photoStubs: [.success([photo0, photo1])],
            dataStubs: [anySuccessData(), anySuccessData()]
        )
        await sut.completePhotosLoading()
        
        XCTAssertTrue(try sut.photoView(at: 0).isShowingLoadingIndicator, "Expect a loading indicator while 1st photo image request is loading")
        XCTAssertTrue(try sut.photoView(at: 1).isShowingLoadingIndicator, "Expect a loading indicator while 2nd photo image request is loading")
        
        try await sut.completeImageDataLoading(at: 0)
        
        XCTAssertFalse(try sut.photoView(at: 0).isShowingLoadingIndicator, "Expect no loading indicator after 1st photo image request is completed")
        XCTAssertFalse(try sut.photoView(at: 1).isShowingLoadingIndicator, "Expect no loading indicator after 2nd photo image request is completed")
    }
    
    @MainActor
    func test_photoView_cancelsImageLoadWhenItIsInvisible() async throws {
        let photo0 = makePhoto(id: "0")
        let photo1 = makePhoto(id: "1")
        let imageData = UIImage.makeData(withColor: .blue)
        let (sut, _) = makeSUT(
            photoStubs: [.success([photo0, photo1])],
            dataStubs: [.success(imageData), .success(imageData)]
        )
        await sut.completePhotosLoading()
        
        try sut.simulatePhotoViewInvisible(at: 1)
        try await sut.completeImageDataLoading(at: 0)
        
        let renderedImageData0 = try sut.photoView(at: 0).imageData()
        let renderedImageData1 = try sut.photoView(at: 1).imageData()
        XCTAssertEqual(renderedImageData0, imageData, "Expect image rendered on first view since it is visible")
        XCTAssertNil(renderedImageData1, "Expect no image rendered on second view since it is invisible")
    }
    
    @MainActor
    func test_photoView_rendersNoImageOnError() async throws {
        let photo0 = makePhoto(id: "0")
        let imageData = UIImage.makeData(withColor: .blue)
        let (sut, _) = makeSUT(
            photoStubs: [.success([photo0])],
            dataStubs: [anyFailure(), .success(imageData)]
        )
        await sut.completePhotosLoading()
        
        try await sut.completeImageDataLoading(at: 0)
        XCTAssertNil(try sut.photoView(at: 0).imageData(), "Expect no image rendered on photo view when photo image request completed with error")
        
        try sut.simulatePhotoViewVisible(at: 0)
        try await sut.completeImageDataLoading(at: 0)
        XCTAssertEqual(try sut.photoView(at: 0).imageData(), imageData, "Expect image rendered on photo view when photo image re-request completed with image data successfully")
    }
    
    // MARK: - Helpers
    
    private func makeSUT(photoStubs: [PhotosLoaderSpy.PhotosResult] = [],
                         dataStubs: [PhotosLoaderSpy.DataResult] = [],
                         function: String = #function,
                         file: StaticString = #file,
                         line: UInt = #line) -> (sut: PhotoGridView, loader: PhotosLoaderSpy) {
        let loader = PhotosLoaderSpy(photoStubs: photoStubs, dataStubs: dataStubs)
        let sut = PhotoGridComposer.composeWith(photosLoader: loader, imageLoader: loader)
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
            try sut.photoView(at: index).authorText(),
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
    
    private func anyFailure() -> PhotosLoaderSpy.DataResult {
        .failure(anyNSError())
    }
    
    private func anySuccessData() -> PhotosLoaderSpy.DataResult {
        .success(Data())
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
    
    func photoView(at index: Int) throws -> PhotoGridItem {
        try photoViews()[index]
    }
    
    func numberOfRenderedViews() throws -> Int {
        try inspectablePhotoViews().count
    }
    
    private func photoViews() throws -> [PhotoGridItem] {
        try inspectablePhotoViews().map { try $0.actualView() }
    }
    
    private func inspectablePhotoViews() throws -> [InspectableView<ViewType.View<PhotoGridItem>>] {
        try inspect().findAll(PhotoGridItem.self)
    }
    
    func completeImageDataLoading(at index: Int) async throws {
        try await photoViewContainers()[index].store.delegate.task?.value
    }
    
    func simulatePhotoViewInvisible(at index: Int) throws {
        try photoViewContainerStack(at: index).callOnDisappear()
    }
    
    func simulatePhotoViewVisible(at index: Int) throws {
        try photoViewContainerStack(at: index).callOnAppear()
    }
    
    private func photoViewContainerStack(at index: Int) throws -> InspectableView<ViewType.ClassifiedView> {
        try inspectablePhotoViewContainers()[index]
            .find(viewWithAccessibilityIdentifier: "photo-grid-item-container-stack")
    }
    
    private func photoViewContainers() throws -> [PhotoGridItemContainer] {
        try inspectablePhotoViewContainers().map { try $0.actualView() }
    }
    
    private func inspectablePhotoViewContainers() throws -> [InspectableView<ViewType.View<PhotoGridItemContainer>>] {
        try inspect().findAll(PhotoGridItemContainer.self)
    }
}

extension PhotoGridItem {
    func authorText() throws -> String {
        try inspect()
            .find(viewWithAccessibilityIdentifier: "photo-grid-item-author")
            .text()
            .string()
    }
    
    func imageData() throws -> Data? {
        try inspect()
            .find(viewWithAccessibilityIdentifier: "photo-grid-item-image")
            .image()
            .actualImage()
            .uiImage()
            .pngData()
    }
    
    var isShowingLoadingIndicator: Bool {
        isLoading
    }
}
