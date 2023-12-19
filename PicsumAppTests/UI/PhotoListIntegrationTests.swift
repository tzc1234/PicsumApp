//
//  PhotoListIntegrationTests.swift
//  PicsumAppTests
//
//  Created by Tsz-Lung on 03/07/2023.
//

import XCTest
import UIKit
@testable import PicsumApp

// *** About complete the async tasks:
// Once trigger `value` from whatever task, all pending tasks will complete at the same time.
// This is annoying! Cannot find a better way to trigger tasks one by one, limit the testability.

final class PhotoListIntegrationTests: XCTestCase {
    
    func test_photosList_hasTitle() {
        let (sut, _) = makeSUT()
        
        XCTAssertEqual(sut.title, PhotoListViewModel.title)
    }
    
    func test_init_doesNotTriggerLoader() {
        let (_, loader) = makeSUT()
        
        XCTAssertEqual(loader.loggedPages.count, 0)
    }
    
    @MainActor
    func test_photoViewSelection_triggersSelection() async {
        let photo = makePhoto()
        var loggedPhotos = [Photo]()
        let (sut, _) = makeSUT(photoStubs: [.success([photo])], selection: { loggedPhotos.append($0) })
        
        sut.simulateAppearance()
        await sut.completePhotosLoading()
        
        XCTAssertEqual(loggedPhotos, [], "Expect no selection triggered before a photo view selected")
        
        sut.simulatePhotoViewSelected(at: 0)
        
        XCTAssertEqual(loggedPhotos, [photo], "Expect a selection triggered once a photo view selected")
    }
    
    @MainActor
    func test_loadPhotosAction_requestsPhotosFromLoader() async {
        let (sut, loader) = makeSUT(photoStubs: [.success([]), .success([]), .success([])])

        XCTAssertEqual(loader.loggedPages.count, 0)

        sut.simulateAppearance()
        await sut.completePhotosLoading()
        XCTAssertEqual(loader.loggedPages.count, 1, "Expect one request once the view is loaded")

        sut.simulateUserInitiatedReload()
        await sut.completePhotosLoading()
        XCTAssertEqual(loader.loggedPages.count, 2, "Expect another request after user initiated a reload")

        sut.simulateUserInitiatedReload()
        await sut.completePhotosLoading()
        XCTAssertEqual(loader.loggedPages.count, 3, "Expect yet another request after user initiated another reload")
    }

    @MainActor
    func test_loadPhotosAction_cancelsPreviousUnfinishedPhotosLoadingBeforeNewPhotosLoading() async throws {
        let photo0 = makePhoto(id: "0")
        let photo1 = makePhoto(id: "1")
        let (sut, _) = makeSUT(photoStubs: [.success([photo0]), .success([photo0, photo1])])

        sut.simulateAppearance()

        XCTAssertEqual(sut.numberOfRenderedPhotoView(), 0, "Expect no rendered view while initial photo loading is not completed")

        sut.simulateUserInitiatedReload()
        await sut.completePhotosLoading()

        XCTAssertEqual(sut.numberOfRenderedPhotoView(), 2, "Expect two rendered view after user initiated photo loading is completed")
    }

    @MainActor
    func test_loadingPhotosIndicator_isVisibleWhileLoadingPhotos() async {
        let (sut, _) = makeSUT(photoStubs: [.success([]), .failure(anyNSError())])

        sut.simulateAppearance()

        XCTAssertTrue(sut.isShowingLoadingIndicator, "Expect an loading indicator once the view is loaded")
        
        await sut.completePhotosLoading()
        
        XCTAssertFalse(sut.isShowingLoadingIndicator, "Expect no loading indicator once photos loading completed")

        sut.simulateUserInitiatedReload()

        XCTAssertTrue(sut.isShowingLoadingIndicator, "Expect an loading indicator again after user initiated a reload")
        
        await sut.completePhotosLoading()
        
        XCTAssertFalse(sut.isShowingLoadingIndicator, "Expect no loading indicator agin after user initiated reload completes with error")
    }

    @MainActor
    func test_loadPhotosCompletion_rendersSuccessfullyLoadedPhotos() async {
        let photo0 = makePhoto(id: "0", author: "author0")
        let photo1 = makePhoto(id: "1", author: "author1")
        let photo2 = makePhoto(id: "2", author: "author2")
        let (sut, _) = makeSUT(photoStubs: [.success([photo0]), .success([photo0, photo1, photo2])],
                               dataStubs: [.failure(anyNSError())])

        sut.simulateAppearance()

        assertThat(sut, isRendering: [])

        await sut.completePhotosLoading()

        assertThat(sut, isRendering: [photo0])

        sut.simulateUserInitiatedReload()
        await sut.completePhotosLoading()

        assertThat(sut, isRendering: [photo0, photo1, photo2])
    }

    @MainActor
    func test_loadPhotosCompletion_doesNotAlterCurrentRenderedPhotoViewsOnError() async {
        let photo0 = makePhoto(id: "0", author: "author0")
        let (sut, _) = makeSUT(photoStubs: [.success([photo0]), .failure(anyNSError())], dataStubs: [anySuccessData()])

        sut.simulateAppearance()

        assertThat(sut, isRendering: [])

        await sut.completePhotosLoading()

        assertThat(sut, isRendering: [photo0])

        sut.simulateUserInitiatedReload()
        await sut.completePhotosLoading()

        assertThat(sut, isRendering: [photo0])
    }
    
    @MainActor
    func test_photoView_loadsImageWhenVisible() async {
        let photo0 = makePhoto(id: "0")
        let photo1 = makePhoto(id: "1")
        let (sut, loader) = makeSUT(
            photoStubs: [.success([photo0, photo1])],
            dataStubs: [anySuccessData(), anySuccessData()])
        
        sut.simulateAppearance()
        await sut.completePhotosLoading()
        
        XCTAssertEqual(loader.loggedPhotoIDs, [], "Expect no image requests until views become visible")
        
        sut.simulatePhotoViewVisible(at: 0)
        await sut.completeImageDataLoading(at: 0)
        XCTAssertEqual(loader.loggedPhotoIDs, [photo0.id], "Expect first image request once first photo view become visible")
        
        sut.simulatePhotoViewVisible(at: 1)
        await sut.completeImageDataLoading(at: 1)
        XCTAssertEqual(loader.loggedPhotoIDs, [photo0.id, photo1.id], "Expect second image request once second photo view become visible")
    }
    
    @MainActor
    func test_photoView_cancelsImageDataTaskWhenNotVisibleAnymore() async throws {
        let photo0 = makePhoto(id: "0")
        let photo1 = makePhoto(id: "1")
        let imageData1 = UIImage.makeData(withColor: .blue)
        let (sut, _) = makeSUT(photoStubs: [.success([photo0, photo1])], dataStubs: [.success(anyData()), .success(imageData1)])
        
        sut.simulateAppearance()
        await sut.completePhotosLoading()
        
        let view0 = try XCTUnwrap(sut.simulatePhotoViewVisible(at: 0))
        let view1 = try XCTUnwrap(sut.simulatePhotoViewVisible(at: 1))
        
        XCTAssertNil(view0.renderedImage, "Expect no image data when first view's task is not completed")
        XCTAssertNil(view1.renderedImage, "Expect no image data when second view's task is not completed")
        
        sut.simulatePhotoViewInvisible(view0, at: 0)
        await sut.completeImageDataLoading(at: 1)
        
        XCTAssertNil(view0.renderedImage, "Expect no image data because first view's task is cancelled when it is not visible anymore")
        XCTAssertEqual(view1.renderedImage, imageData1, "Expect the second image is loaded after its data task is completed")
    }
    
    @MainActor
    func test_photoView_noStateChangeWhenViewFromBecomevisibleAgainToInvisibleInAShortPeriodOfTime() async throws {
        let photo = makePhoto(id: "0")
        let imageData0 = UIImage.makeData(withColor: .red)
        let imageData1 = UIImage.makeData(withColor: .blue)
        let (sut, _) = makeSUT(photoStubs: [.success([photo])],
                               dataStubs: [.success(imageData0), .success(imageData1)])
        
        sut.simulateAppearance()
        await sut.completePhotosLoading()
        
        let view = try XCTUnwrap(sut.simulatePhotoViewVisible(at: 0))
        await sut.completeImageDataLoading(at: 0)
        
        XCTAssertFalse(view.isShowingImageLoadingIndicator, "Expect no loading indicator after image loading completed")
        XCTAssertEqual(view.renderedImage, imageData0, "Expect the image is rendered after image loading completed")
        
        sut.simulatePhotoViewBecomeVisibleAgain(view, at: 0)
        
        XCTAssertTrue(view.isShowingImageLoadingIndicator, "Expect a loading indicator for view when it become visible again")
        XCTAssertEqual(view.renderedImage, imageData0, "Expect the image is unchanged because image loading is not completed")
        
        sut.simulatePhotoViewInvisible(view, at: 0)
        await sut.completeImageDataLoading(at: 0)
        
        XCTAssertTrue(view.isShowingImageLoadingIndicator, "Expect a loading indicator for view once view is invisible")
        XCTAssertEqual(view.renderedImage, imageData0, "Expect the image is unchanged because the view is invisible")
    }
    
    @MainActor
    func test_photoView_loadsImageWhileInvisibleViewIsVisibleAgain() async throws {
        let photo0 = makePhoto(id: "0")
        let (sut, loader) = makeSUT(photoStubs: [.success([photo0])], dataStubs: [anySuccessData(), anySuccessData()])
        
        sut.simulateAppearance()
        await sut.completePhotosLoading()
        
        let view = try XCTUnwrap(sut.simulatePhotoViewVisible(at: 0))
        await sut.completeImageDataLoading(at: 0)
        XCTAssertEqual(loader.loggedPhotoIDs, [photo0.id], "Expect image request once photo view become visible")
        
        sut.simulatePhotoViewInvisible(view, at: 0)
        await sut.completeImageDataLoading(at: 0)
        XCTAssertEqual(loader.loggedPhotoIDs, [photo0.id], "Expect image request stay unchanged when photo view become invisible")
        
        sut.simulatePhotoViewBecomeVisibleAgain(view, at: 0)
        await sut.completeImageDataLoading(at: 0)
        XCTAssertEqual(loader.loggedPhotoIDs, [photo0.id, photo0.id], "Expect image request again once photo view become visible again")
    }
    
    @MainActor
    func test_photoViewLoadingIndicator_isVisibleWhileLoadingImage() async throws {
        let photo0 = makePhoto(id: "0")
        let photo1 = makePhoto(id: "1")
        let (sut, _) = makeSUT(photoStubs: [.success([photo0, photo1])], dataStubs: [anySuccessData(), anySuccessData()])
        
        sut.simulateAppearance()
        await sut.completePhotosLoading()
        
        let view0 = try XCTUnwrap(sut.simulatePhotoViewVisible(at: 0))
        let view1 = try XCTUnwrap(sut.simulatePhotoViewVisible(at: 1))
        
        XCTAssertTrue(view0.isShowingImageLoadingIndicator, "Expect loading indicator for first view while loading first image")
        XCTAssertTrue(view1.isShowingImageLoadingIndicator, "Expect loading indicator for second view while loading second image")
        
        await sut.completeImageDataLoading(at: 0)
        
        XCTAssertFalse(view0.isShowingImageLoadingIndicator, "Expect no loading indicator for first view after loading first image completion")
        XCTAssertFalse(view1.isShowingImageLoadingIndicator, "Expect no loading indicator for second view after loading second image completion")
    }
    
    @MainActor
    func test_photoView_rendersImageLoadedFromPhoto() async throws {
        let photo0 = makePhoto(id: "0")
        let photo1 = makePhoto(id: "1")
        let imageData0 = UIImage.makeData(withColor: .red)
        let imageData1 = UIImage.makeData(withColor: .blue)
        let (sut, _) = makeSUT(photoStubs: [.success([photo0, photo1])], dataStubs: [.success(imageData0), .success(imageData1)])
        
        sut.simulateAppearance()
        await sut.completePhotosLoading()
        
        let view0 = try XCTUnwrap(sut.simulatePhotoViewVisible(at: 0))
        let view1 = try XCTUnwrap(sut.simulatePhotoViewVisible(at: 1))
        
        XCTAssertEqual(view0.renderedImage, .none, "Expect no image for first view while loading first image")
        XCTAssertEqual(view1.renderedImage, .none, "Expect no image for second view while loading second image")
        
        await sut.completeImageDataLoading(at: 0)
        
        XCTAssertEqual(view0.renderedImage, imageData0, "Expect image for first view once loading first image completed")
        XCTAssertEqual(view1.renderedImage, imageData1, "Expect image for second view once loading second image completed")
    }
    
    @MainActor
    func test_photoView_rendersNoImageOnError() async throws {
        let photo0 = makePhoto(id: "0")
        let imageData0 = UIImage.makeData(withColor: .red)
        let (sut, _) = makeSUT(photoStubs: [.success([photo0])],
                               dataStubs: [.failure(anyNSError()), .success(imageData0)])
        
        sut.simulateAppearance()
        await sut.completePhotosLoading()
        
        let view0 = try XCTUnwrap(sut.simulatePhotoViewVisible(at: 0))
        
        XCTAssertEqual(view0.renderedImage, .none, "Expect no image for view while loading")
        
        await sut.completeImageDataLoading(at: 0)
        
        XCTAssertEqual(view0.renderedImage, .none, "Expect no image for view while loading image complete with error")
        
        sut.simulatePhotoViewInvisible(view0, at: 0)
        sut.simulatePhotoViewBecomeVisibleAgain(view0, at: 0)
        await sut.completeImageDataLoading(at: 0)
        
        XCTAssertEqual(view0.renderedImage, imageData0, "Expect an image for view once loading image completed successfully after view visible again")
    }
    
    @MainActor
    func test_photoView_rendersNoImageOnInvalidImageData() async throws {
        let photo0 = makePhoto(id: "0")
        let invalidData = Data("invalid data".utf8)
        let (sut, _) = makeSUT(photoStubs: [.success([photo0])], dataStubs: [.success(invalidData)])
        
        sut.simulateAppearance()
        await sut.completePhotosLoading()
        
        let view0 = try XCTUnwrap(sut.simulatePhotoViewVisible(at: 0))
        
        XCTAssertEqual(view0.renderedImage, .none, "Expect no image for view while loading first image")
        
        await sut.completeImageDataLoading(at: 0)
        
        XCTAssertEqual(view0.renderedImage, .none, "Expect no image for view once loading image complete with invalid image data")
    }
    
    @MainActor
    func test_photoView_configuresViewCorrectlyWhenBecomingVisibleAgain() async throws {
        let photo0 = makePhoto(id: "0")
        let imageData0 = UIImage.makeData(withColor: .red)
        let (sut, _) = makeSUT(photoStubs: [.success([photo0])], dataStubs: [.success(imageData0), .success(imageData0)])
        
        sut.simulateAppearance()
        await sut.completePhotosLoading()
        
        let view0 = try XCTUnwrap(sut.simulatePhotoViewVisible(at: 0))
        sut.simulatePhotoViewInvisible(view0, at: 0)
        sut.simulatePhotoViewBecomeVisibleAgain(view0, at: 0)
        
        XCTAssertNil(view0.renderedImage, "Expect no image when view become visible again but image loading not yet completed")
        XCTAssertTrue(view0.isShowingImageLoadingIndicator, "Expected loading indicator when view was visible and becomes visible again")
        
        await sut.completeImageDataLoading(at: 0)
        
        XCTAssertEqual(view0.renderedImage, imageData0, "Expected rendered image when image loads successfully after view becomes visible again")
        XCTAssertFalse(view0.isShowingImageLoadingIndicator, "Expected no loading indicator when image loads successfully after view becomes visible again")
    }
    
    @MainActor
    func test_photoView_rendersMoreViewWhenNextPageLoadingCompleted() async throws {
        let photo0 = makePhoto(id: "0")
        let photo1 = makePhoto(id: "1")
        let photo2 = makePhoto(id: "2")
        let imageData0 = UIImage.makeData(withColor: .red)
        let imageData1 = UIImage.makeData(withColor: .blue)
        let imageData2 = UIImage.makeData(withColor: .green)
        let (sut, _) = makeSUT(
            photoStubs: [.success([photo0]), .success([photo1, photo2])],
            dataStubs: [.success(imageData0), .success(imageData1), .success(imageData2)]
        )
        
        sut.simulateAppearance()
        await sut.completePhotosLoading()
        
        let view0 = try XCTUnwrap(sut.simulatePhotoViewVisible(at: 0))
        await sut.completeImageDataLoading(at: 0)
        
        XCTAssertEqual(sut.numberOfRenderedPhotoView(), 1, "Expect one view rendered after first page loaded")
        XCTAssertEqual(view0.renderedImage, imageData0, "Expected rendered image for first view when first view become visible")
        
        sut.simulateUserInitiatedLoadMore()
        await sut.completeMorePhotosLoading()
        
        XCTAssertEqual(sut.numberOfRenderedPhotoView(), 3, "Expect three views rendered after second page loaded")
        
        let view1 = try XCTUnwrap(sut.simulatePhotoViewVisible(at: 1))
        let view2 = try XCTUnwrap(sut.simulatePhotoViewVisible(at: 2))
        await sut.completeImageDataLoading(at: 1)
        
        XCTAssertEqual(view0.renderedImage, imageData0, "Expected rendered image for first view keep unchanged")
        XCTAssertEqual(view1.renderedImage, imageData1, "Expected rendered image for second view when second view become visible")
        XCTAssertEqual(view2.renderedImage, imageData2, "Expected rendered image for third view when third view become visible")
    }
    
    @MainActor
    func test_errorView_showsErrorWhenPhotoRequestOnError() async throws {
        let (sut, _) = makeSUT(photoStubs: [.success([]), .failure(anyNSError())])
        let window = UIWindow()
        window.addSubview(sut.view)
        
        sut.simulateAppearance()
        await sut.completePhotosLoading()
        
        XCTAssertNil(sut.presentedViewController, "Expect no error view after loading photo successfully")
        
        sut.simulateUserInitiatedReload()
        await sut.completePhotosLoading()
        
        let alert = try XCTUnwrap(sut.presentedViewController as? UIAlertController)
        XCTAssertEqual(alert.message, PhotoListViewModel.errorMessage)
        
        let exp = expectation(description: "Wait for sut dismiss to prevent memory leak.")
        sut.dismiss(animated: false) { exp.fulfill() }
        await fulfillment(of: [exp])
    }

    // MARK: - Helpers

    private func makeSUT(photoStubs: [PhotosLoaderSpy.PhotosResult] = [],
                         dataStubs: [PhotosLoaderSpy.DataResult] = [],
                         selection: @escaping (Photo) -> Void = { _ in },
                         file: StaticString = #file,
                         line: UInt = #line) -> (sut: PhotoListViewController, loader: PhotosLoaderSpy) {
        let loader = PhotosLoaderSpy(photoStubs: photoStubs, dataStubs: dataStubs)
        let viewModel = PhotoListViewModel(loader: loader)
        let sut = PhotoListComposer.composeWith(viewModel: viewModel, imageLoader: loader, selection: selection)
        
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
        guard let view = sut.simulatePhotoViewVisible(at: index) else {
            XCTFail("Expect a photo view at index \(index)", file: file, line: line)
            return
        }
        
        XCTAssertEqual(view.authorText, photo.author, "Expect author: \(photo.author) for index \(index)", file: file, line: line)
    }
    
    private func anySuccessData() -> PhotosLoaderSpy.DataResult {
        .success(Data())
    }
    
}
