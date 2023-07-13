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
        let (sut, _) = makeSUT(photoStubs: [.success([photo0]), .success([photo0, photo1, photo2])],
                               dataStubs: [.failure(anyNSError())])

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
        let (sut, _) = makeSUT(photoStubs: [.success([photo0]), .failure(anyNSError())], dataStubs: [anySuccessData()])

        sut.loadViewIfNeeded()

        assertThat(sut, isRendering: [])

        await sut.reloadPhotosTask?.value

        assertThat(sut, isRendering: [photo0])

        sut.simulateUserInitiatedReload()
        await sut.reloadPhotosTask?.value

        assertThat(sut, isRendering: [photo0])
    }
    
    @MainActor
    func test_photoView_loadsImageWhenVisiable() async {
        let photo0 = makePhoto(id: "0")
        let photo1 = makePhoto(id: "1")
        let (sut, loader) = makeSUT(
            photoStubs: [.success([photo0, photo1])],
            dataStubs: [anySuccessData(), anySuccessData()])
        
        sut.loadViewIfNeeded()
        await sut.reloadPhotosTask?.value
        
        XCTAssertEqual(loader.loggedPhotoIDs, [], "Expect no image requests until views become visiable")
        
        sut.simulatePhotoViewVisible(at: 0)
        await sut.imageDataTask(at: 0)?.value
        XCTAssertEqual(loader.loggedPhotoIDs, [photo0.id], "Expect first image request once first photo view become visiable")
        
        sut.simulatePhotoViewVisible(at: 1)
        await sut.imageDataTask(at: 1)?.value
        XCTAssertEqual(loader.loggedPhotoIDs, [photo0.id, photo1.id], "Expect second image request once second photo view become visiable")
    }
    
    @MainActor
    func test_photoView_cancelsImageDataTaskWhenNotVisibleAnymore() async throws {
        let photo0 = makePhoto(id: "0")
        let photo1 = makePhoto(id: "1")
        let imageData1 = UIImage.make(withColor: .blue).pngData()!
        let (sut, _) = makeSUT(photoStubs: [.success([photo0, photo1])], dataStubs: [.success(anyData()), .success(imageData1)])
        
        sut.loadViewIfNeeded()
        await sut.reloadPhotosTask?.value
        
        let view0 = try XCTUnwrap(sut.simulatePhotoViewVisible(at: 0))
        let view1 = try XCTUnwrap(sut.simulatePhotoViewVisible(at: 1))
        
        XCTAssertNil(view0.renderedImage, "Expect no image data when first view's task is not completed")
        XCTAssertNil(view1.renderedImage, "Expect no image data when second view's task is not completed")
        
        sut.simulatePhotoViewNotVisible(view0, at: 0)
        await sut.imageDataTask(at: 1)?.value
        
        XCTAssertNil(view0.renderedImage, "Expect no image data because first view's task is cancelled when it is not visible anymore")
        XCTAssertEqual(view1.renderedImage, imageData1, "Expect the second image is loaded after its data task is completed")
    }
    
    @MainActor
    func test_photoView_loadsImageWhileInvisibleViewIsVisibleAgain() async throws {
        let photo0 = makePhoto(id: "0")
        let (sut, loader) = makeSUT(photoStubs: [.success([photo0])], dataStubs: [anySuccessData(), anySuccessData()])
        
        sut.loadViewIfNeeded()
        await sut.reloadPhotosTask?.value
        
        let view = try XCTUnwrap(sut.simulatePhotoViewVisible(at: 0))
        await sut.imageDataTask(at: 0)?.value
        XCTAssertEqual(loader.loggedPhotoIDs, [photo0.id], "Expect image request once photo view become visiable")
        
        sut.simulatePhotoViewNotVisible(view, at: 0)
        await sut.imageDataTask(at: 0)?.value
        XCTAssertEqual(loader.loggedPhotoIDs, [photo0.id], "Expect image request stay unchanged when photo view become invisiable")
        
        sut.simulatePhotoViewBecomeVisibleAgain(view, at: 0)
        await sut.imageDataTask(at: 0)?.value
        XCTAssertEqual(loader.loggedPhotoIDs, [photo0.id, photo0.id], "Expect image request again once photo view will become visiable again")
    }
    
    @MainActor
    func test_photoViewLoadingIndicator_isVisibleWhileLoadingImage() async throws {
        let photo0 = makePhoto(id: "0")
        let photo1 = makePhoto(id: "1")
        let (sut, _) = makeSUT(photoStubs: [.success([photo0, photo1])], dataStubs: [anySuccessData(), anySuccessData()])
        
        sut.loadViewIfNeeded()
        await sut.reloadPhotosTask?.value
        
        let view0 = try XCTUnwrap(sut.simulatePhotoViewVisible(at: 0))
        let view1 = try XCTUnwrap(sut.simulatePhotoViewVisible(at: 1))
        
        XCTAssertTrue(view0.isShowingImageLoadingIndicator, "Expect loading indicator for first view while loading first image")
        XCTAssertTrue(view1.isShowingImageLoadingIndicator, "Expect loading indicator for second view while loading second image")
        
        // Once trigger `value` from whatever Task, all pending tasks will complete at the same time.
        // This is annoying! Cannot find a better way to one by one triggering Tasks.
        await sut.imageDataTask(at: 0)?.value
        
        XCTAssertFalse(view0.isShowingImageLoadingIndicator, "Expect no loading indicator for first view after loading first image completion")
        XCTAssertFalse(view1.isShowingImageLoadingIndicator, "Expect no loading indicator for second view after loading second image completion")
    }
    
    @MainActor
    func test_photoView_rendersImageLoadedFromPhoto() async throws {
        let photo0 = makePhoto(id: "0")
        let photo1 = makePhoto(id: "1")
        let imageData0 = UIImage.make(withColor: .red).pngData()!
        let imageData1 = UIImage.make(withColor: .blue).pngData()!
        let (sut, _) = makeSUT(photoStubs: [.success([photo0, photo1])], dataStubs: [.success(imageData0), .success(imageData1)])
        
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
    
    @MainActor
    func test_photoView_rendersNoImageOnError() async throws {
        let photo0 = makePhoto(id: "0")
        let imageData0 = UIImage.make(withColor: .red).pngData()!
        let (sut, _) = makeSUT(photoStubs: [.success([photo0])],
                               dataStubs: [.failure(anyNSError()), .success(imageData0)])
        
        sut.loadViewIfNeeded()
        await sut.reloadPhotosTask?.value
        
        let view0 = try XCTUnwrap(sut.simulatePhotoViewVisible(at: 0))
        
        XCTAssertEqual(view0.renderedImage, .none, "Expect no image for view while loading")
        
        await sut.imageDataTask(at: 0)?.value
        
        XCTAssertEqual(view0.renderedImage, .none, "Expect no image for view while loading image complete with error")
        
        sut.simulatePhotoViewNotVisible(view0, at: 0)
        sut.simulatePhotoViewBecomeVisibleAgain(view0, at: 0)
        await sut.imageDataTask(at: 0)?.value
        
        XCTAssertEqual(view0.renderedImage, imageData0, "Expect an image for view once loading image completed successfully after view visiable again")
    }
    
    @MainActor
    func test_photoView_rendersNoImageOnInvalidImageData() async throws {
        let photo0 = makePhoto(id: "0")
        let invalidData = Data("invalid data".utf8)
        let (sut, _) = makeSUT(photoStubs: [.success([photo0])], dataStubs: [.success(invalidData)])
        
        sut.loadViewIfNeeded()
        await sut.reloadPhotosTask?.value
        
        let view0 = try XCTUnwrap(sut.simulatePhotoViewVisible(at: 0))
        
        XCTAssertEqual(view0.renderedImage, .none, "Expect no image for view while loading first image")
        
        await sut.imageDataTask(at: 0)?.value
        
        XCTAssertEqual(view0.renderedImage, .none, "Expect no image for view once loading image complete with invalid image data")
    }
    
    @MainActor
    func test_photoView_configuresViewCorrectlyWhenBecomingVisibleAgain() async throws {
        let photo0 = makePhoto(id: "0")
        let imageData0 = UIImage.make(withColor: .red).pngData()!
        let (sut, _) = makeSUT(photoStubs: [.success([photo0])], dataStubs: [.failure(anyNSError()), .success(imageData0)])
        
        sut.loadViewIfNeeded()
        await sut.reloadPhotosTask?.value
        
        let view0 = try XCTUnwrap(sut.simulatePhotoViewVisible(at: 0))
        sut.simulatePhotoViewNotVisible(view0, at: 0)
        sut.simulatePhotoViewBecomeVisibleAgain(view0, at: 0)
        
        XCTAssertEqual(view0.renderedImage, .none, "Expect no image when view become visiable again")
        XCTAssertTrue(view0.isShowingImageLoadingIndicator, "Expected loading indicator when view was visible and becomes visible again")
        
        await sut.imageDataTask(at: 0)?.value
        
        XCTAssertEqual(view0.renderedImage, imageData0, "Expected rendered image when image loads successfully after view becomes visible again")
        XCTAssertFalse(view0.isShowingImageLoadingIndicator, "Expected no loading indicator when image loads successfully after view becomes visible again")
    }
    
    @MainActor
    func test_errorView_showErrorWhenPhotoRequestOnError() async throws {
        let (sut, _) = makeSUT(photoStubs: [.success([]), .failure(anyNSError())])
        let window = UIWindow()
        window.addSubview(sut.view)
        
        sut.loadViewIfNeeded()
        await sut.reloadPhotosTask?.value
        
        XCTAssertNil(sut.presentedViewController, "Expect no error view after loading photo successfully")
        
        sut.simulateUserInitiatedReload()
        await sut.reloadPhotosTask?.value
        
        let alert = try XCTUnwrap(sut.presentedViewController as? UIAlertController)
        XCTAssertEqual(alert.message, PhotoListViewModel.errorMessage)
        
        let exp = expectation(description: "Wait for sut dismiss to prevent memory leak.")
        sut.dismiss(animated: false) { exp.fulfill() }
        await fulfillment(of: [exp])
    }

    // MARK: - Helpers

    private func makeSUT(photoStubs: [PhotosLoaderSpy.PhotosResult] = [],
                         dataStubs: [PhotosLoaderSpy.DataResult] = [],
                         file: StaticString = #file,
                         line: UInt = #line) -> (sut: PhotoListViewController, loader: PhotosLoaderSpy) {
        let loader = PhotosLoaderSpy(photoStubs: photoStubs, dataStubs: dataStubs)
        let viewModel = PhotoListViewModel(loader: loader)
        let sut = PhotoListComposer.composeWith(viewModel: viewModel, imageLoader: loader)
        
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
    
    private func anySuccessData() -> PhotosLoaderSpy.DataResult {
        .success(Data())
    }
    
}
