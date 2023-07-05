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
    func test_loadPhotosAction_requestsPhotosFromLoader() async {
        let (sut, loader) = makeSUT(photoStubs: [.success([]), .success([]), .success([])])
        
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
    func test_loadPhotosAction_cancelsPreviousUnfinishedTaskBeforeNewRequest() async throws {
        let (sut, _) = makeSUT(photoStubs: [.success([]), .success([])])
        
        sut.loadViewIfNeeded()
        let previousTask = try XCTUnwrap(sut.reloadPhotosTask)
        
        XCTAssertEqual(previousTask.isCancelled, false)
        
        sut.simulateUserInitiatedReload()
        await sut.reloadPhotosTask?.value
        
        XCTAssertEqual(previousTask.isCancelled, true)
    }
    
    @MainActor
    func test_loadingPhotosIndicator_isVisiableWhileLoadingPhotos() async {
        let (sut, loader) = makeSUT(photoStubs: [.success([]), .failure(anyNSError())])

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
        XCTAssertFalse(sut.isShowingLoadingIndicator, "Expect not showing loading indicator agin after user initiated reload completes with error")
    }
    
    @MainActor
    func test_loadPhotosCompletion_rendersSuccessfullyLoadedPhotos() async throws {
        let photo0 = makePhoto(id: "0", author: "author0")
        let photo1 = makePhoto(id: "1", author: "author1")
        let photo2 = makePhoto(id: "2", author: "author2")
        let (sut, _) = makeSUT(photoStubs: [.success([photo0]), .success([photo0, photo1, photo2])])
        
        sut.loadViewIfNeeded()
        
        assertThat(sut, isRendering: [])
        
        await sut.reloadPhotosTask?.value
        
        assertThat(sut, isRendering: [photo0])
        
        sut.simulateUserInitiatedReload()
        await sut.reloadPhotosTask?.value
        
        assertThat(sut, isRendering: [photo0, photo1, photo2])
    }
    
    @MainActor
    func test_loadPhotosCompletion_doesNotAlterCurrentRenderedPhotoViewsOnError() async throws {
        let photo0 = makePhoto(id: "0", author: "author0")
        let (sut, _) = makeSUT(photoStubs: [.success([photo0]), .failure(anyNSError())])
        
        sut.loadViewIfNeeded()
        
        assertThat(sut, isRendering: [])
        
        await sut.reloadPhotosTask?.value
        
        assertThat(sut, isRendering: [photo0])
        
        sut.simulateUserInitiatedReload()
        await sut.reloadPhotosTask?.value
        
        assertThat(sut, isRendering: [photo0])
    }
    
    @MainActor
    func test_photoView_loadsImageURLWhenVisiable() async {
        let photo0 = makePhoto(id: "0", url: URL(string: "https://url-0.com")!)
        let photo1 = makePhoto(id: "1", url: URL(string: "https://url-1.com")!)
        let (sut, loader) = makeSUT(
            photoStubs: [.success([photo0, photo1])],
            dataStubs: [Data(), Data()])
        
        sut.loadViewIfNeeded()
        await sut.reloadPhotosTask?.value
        
        XCTAssertEqual(loader.loadedImageURLs, [], "Expect no image URL requests until views become visiable")
        
        sut.simulatePhotoViewVisible(at: 0)
        await sut.imageDataTask(at: 0)?.value
        XCTAssertEqual(loader.loadedImageURLs, [photo0.url], "Expect first image URL request once first photo view become visiable")
        
        sut.simulatePhotoViewVisible(at: 1)
        await sut.imageDataTask(at: 1)?.value
        XCTAssertEqual(loader.loadedImageURLs, [photo0.url, photo1.url], "Expect second image URL request once second photo view become visiable")
    }
    
    @MainActor
    func test_photoView_cancelsImageDataTaskWhenNotVisibleAnymore() async throws {
        let photo0 = makePhoto(id: "0", url: URL(string: "https://url-0.com")!)
        let photo1 = makePhoto(id: "1", url: URL(string: "https://url-1.com")!)
        let (sut, _) = makeSUT(photoStubs: [.success([photo0, photo1])], dataStubs: [Data(), Data()])
        
        sut.loadViewIfNeeded()
        await sut.reloadPhotosTask?.value
        
        let view0 = try XCTUnwrap(sut.simulatePhotoViewVisible(at: 0))
        let view1 = try XCTUnwrap(sut.simulatePhotoViewVisible(at: 1))
        let task0 = try XCTUnwrap(sut.imageDataTask(at: 0))
        let task1 = try XCTUnwrap(sut.imageDataTask(at: 1))
        
        XCTAssertFalse(task0.isCancelled, "Expect the first image data task started when first photo view is visible")
        XCTAssertFalse(task1.isCancelled, "Expect the second image data task started when excond photo view is visible")
        
        sut.simulatePhotoViewNotVisible(view0, at: 0)
        sut.simulatePhotoViewNotVisible(view1, at: 1)
        
        XCTAssertTrue(task0.isCancelled, "Expect the first image data task is cancelled when first photo view is not visible anymore")
        XCTAssertTrue(task1.isCancelled, "Expect the second image data task is cancelled when second photo view is not visible anymore")
    }
    
    @MainActor
    func test_photoView_loadsImageURLWhileInvisibleViewIsVisibleAgain() async throws {
        let photo0 = makePhoto(id: "0", url: URL(string: "https://url-0.com")!)
        let (sut, loader) = makeSUT(photoStubs: [.success([photo0])], dataStubs: [Data(), Data()])
        
        sut.loadViewIfNeeded()
        await sut.reloadPhotosTask?.value
        
        let view = try XCTUnwrap(sut.simulatePhotoViewVisible(at: 0))
        await sut.imageDataTask(at: 0)?.value
        XCTAssertEqual(loader.loadedImageURLs, [photo0.url], "Expect image URL request once photo view become visiable")
        
        sut.simulatePhotoViewNotVisible(view, at: 0)
        await sut.imageDataTask(at: 0)?.value
        XCTAssertEqual(loader.loadedImageURLs, [photo0.url], "Expect image URL request stay unchanged when photo view become invisiable")
        
        sut.simulatePhotoViewWillVisibleAgain(view, at: 0)
        await sut.imageDataTask(at: 0)?.value
        XCTAssertEqual(loader.loadedImageURLs, [photo0.url, photo0.url], "Expect image URL request again once photo view will become visiable again")
    }
    
    @MainActor
    func test_photoViewLoadingIndicator_isVisibleWhileLoadingImage() async throws {
        let photo0 = makePhoto(id: "0", url: URL(string: "https://url-0.com")!)
        let photo1 = makePhoto(id: "1", url: URL(string: "https://url-1.com")!)
        let (sut, _) = makeSUT(photoStubs: [.success([photo0, photo1])], dataStubs: [Data(), Data()])
        
        sut.loadViewIfNeeded()
        await sut.reloadPhotosTask?.value
        
        let view0 = try XCTUnwrap(sut.simulatePhotoViewVisible(at: 0))
        let view1 = try XCTUnwrap(sut.simulatePhotoViewVisible(at: 1))
        
        XCTAssertTrue(view0.isShowingImageLoadingIndicator, "Expect loading indicator for first view while loading first image")
        XCTAssertTrue(view1.isShowingImageLoadingIndicator, "Expect loading indicator for second view while loading second image")
        
        // Once trigger `.value` from whatever Task, all other tasks will complete at the same time.
        // Cannot find a better way to one by one triggering Tasks.
        await sut.imageDataTask(at: 0)?.value
//        await sut.imageDataTask(at: 1)?.value
        
        XCTAssertFalse(view0.isShowingImageLoadingIndicator, "Expect no loading indicator for first view after loading first image completion")
        XCTAssertFalse(view1.isShowingImageLoadingIndicator, "Expect no loading indicator for second view after loading second image completion")
    }
    
    @MainActor
    func test_photoView_rendersImageLoadedFromURL() async throws {
        let photo0 = makePhoto(id: "0", url: URL(string: "https://url-0.com")!)
        let photo1 = makePhoto(id: "1", url: URL(string: "https://url-1.com")!)
        let imageData0 = UIImage.make(withColor: .red).pngData()!
        let imageData1 = UIImage.make(withColor: .blue).pngData()!
        let (sut, _) = makeSUT(photoStubs: [.success([photo0, photo1])], dataStubs: [imageData0, imageData1])
        
        sut.loadViewIfNeeded()
        await sut.reloadPhotosTask?.value
        
        let view0 = try XCTUnwrap(sut.simulatePhotoViewVisible(at: 0))
        let view1 = try XCTUnwrap(sut.simulatePhotoViewVisible(at: 1))
        
        XCTAssertEqual(view0.renderedImage, .none, "Expect no image for first view while loading first image")
        XCTAssertEqual(view1.renderedImage, .none, "Expect no image for second view while loading second image")
        
        await sut.imageDataTask(at: 0)?.value
        
        XCTAssertEqual(view0.renderedImage, imageData0, "Expect image for first view once loading first image completed")
        XCTAssertEqual(view1.renderedImage, imageData1, "Expect image for second view once loading second image completed")
    }

    // MARK: - Helpers
    
    private typealias Result = PhotosLoaderSpy.Result
    
    private func makeSUT(photoStubs: [Result] = [], dataStubs: [Data] = [],
                         file: StaticString = #file,
                         line: UInt = #line) -> (sut: PhotoListViewController, loader: PhotosLoaderSpy) {
        let loader = PhotosLoaderSpy(photoStubs: photoStubs, dataStubs: dataStubs)
        let viewModel = PhotoListViewModel(loader: loader)
        let sut = PhotoListViewController(viewModel: viewModel, imageLoader: loader)
        
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
        collectionView.refreshControl?.simulatePullToRefresh()
    }
    
    var isShowingLoadingIndicator: Bool {
        collectionView.refreshControl?.isRefreshing == true
    }
    
    func numberOfRenderedPhotoView() -> Int {
        collectionView.numberOfSections > photoViewSection ? collectionView.numberOfItems(inSection: photoViewSection) : 0
    }
    
    func photoView(at item: Int) -> PhotoListCell? {
        let ds = collectionView.dataSource
        let indexPath = IndexPath(item: item, section: 0)
        return ds?.collectionView(collectionView, cellForItemAt: indexPath) as? PhotoListCell
    }
    
    @discardableResult
    func simulatePhotoViewVisible(at item: Int) -> PhotoListCell? {
        photoView(at: item)
    }
    
    func simulatePhotoViewNotVisible(_ view: PhotoListCell, at item: Int) {
        let d = collectionView.delegate
        let indexPath = IndexPath(item: item, section: 0)
        d?.collectionView?(collectionView, didEndDisplaying: view, forItemAt: indexPath)
    }
    
    func simulatePhotoViewWillVisibleAgain(_ view: PhotoListCell, at item: Int) {
        let d = collectionView.delegate
        let indexPath = IndexPath(item: item, section: 0)
        d?.collectionView?(collectionView, willDisplay: view, forItemAt: indexPath)
    }
    
    private var photoViewSection: Int {
        0
    }
    
    func imageDataTask(at item: Int) -> Task<Void, Never>? {
        imageDataTasks[.init(item: item, section: photoViewSection)]
    }
}

extension PhotoListCell {
    var authorText: String? {
        authorLabel.text
    }
    
    var isShowingImageLoadingIndicator: Bool {
        imageView.isShimmering
    }
    
    var renderedImage: Data? {
        imageView.image?.pngData()
    }
}
