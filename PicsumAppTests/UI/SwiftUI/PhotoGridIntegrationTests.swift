//
//  PhotoGridIntegrationTests.swift
//  PicsumAppTests
//
//  Created by Tsz-Lung on 15/01/2024.
//

import XCTest
import ViewInspector
@testable import PicsumApp

final class PhotoGridIntegrationTests: XCTestCase, PhotosLoaderSpyResultHelpersForTest {
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
        let (sut, _) = makeSUT(photoStubs: [.success([photo0]), .success([photo1, photo2]), .success([photo0])])
        
        await sut.completePhotosLoading()
        
        try assertThat(try sut.photoViews(), isRendering: [photo0])
        
        await sut.completeLoadMorePhotos()
        
        try assertThat(try sut.photoViews(), isRendering: [photo0, photo1, photo2])
        
        sut.simulateUserInitiateReload()
        await sut.completePhotosLoading()
        
        try assertThat(try sut.photoViews(), isRendering: [photo0])
    }
    
    @MainActor
    func test_loadPhotosCompletion_doesNotAlterCurrentRenderedPhotoViewsOnLoaderError() async throws {
        let photo0 = makePhoto(id: "0", author: "author0")
        let photo1 = makePhoto(id: "1", author: "author1")
        let (sut, _) = makeSUT(photoStubs: [.success([photo0, photo1]), anyFailure()])
        
        await sut.completePhotosLoading()
        
        try assertThat(try sut.photoViews(), isRendering: [photo0, photo1])
        
        sut.simulateUserInitiateReload()
        await sut.completePhotosLoading()
        
        try assertThat(try sut.photoViews(), isRendering: [photo0, photo1])
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
        let container = try XCTUnwrap(sut.inspectablePhotoViewContainers().first)
        try await container.completeImageDataLoading()
        
        XCTAssertEqual(loader.loggedPhotoIDSet, [photo0.id, photo1.id], "Expect 2 photo data requests after 2 photo views are rendered")
    }
    
    @MainActor
    func test_photoView_loadsImageAgainWhileInvisibleViewIsVisibleAgain() async throws {
        let photo0 = makePhoto(id: "0")
        let (sut, loader) = makeSUT(photoStubs: [.success([photo0])], dataStubs: [anySuccessData(), anySuccessData()])
        
        await sut.completePhotosLoading()
        
        let container = try sut.inspectablePhotoViewContainer()
        try await container.completeImageDataLoading()
        XCTAssertEqual(loader.loggedPhotoIDs, [photo0.id], "Expect 1 photo data request after photo view is visible")
        
        try container.simulatePhotoViewInvisible()
        XCTAssertEqual(loader.loggedPhotoIDs, [photo0.id], "Expect no photo data requests changes after photo view is invisible")
        
        try container.simulatePhotoViewVisible()
        try await container.completeImageDataLoading()
        XCTAssertEqual(loader.loggedPhotoIDs, [photo0.id, photo0.id], "Expect 2 photo data requests after photo view is visible again")
    }
    
    @MainActor
    func test_photoView_loadsImageWhenItIsInitialisedAgain() async throws {
        let photo0 = makePhoto(id: "0")
        let (sut, loader) = makeSUT(
            photoStubs: [.success([photo0]), .success([])],
            dataStubs: [anySuccessData(), anySuccessData()]
        )
        
        await sut.completePhotosLoading()
        await sut.completeLoadMorePhotos()
        
        let container = try XCTUnwrap(sut.inspectablePhotoViewContainer())
        try await container.completeImageDataLoading()
        
        XCTAssertEqual(loader.loggedPhotoIDs, [photo0.id], "Expect 1 photo data request after photo view is visible")
        
        try container.simulatePhotoViewInvisible()
        XCTAssertEqual(loader.loggedPhotoIDs, [photo0.id], "Expect no photo data requests changes after photo view is invisible")
        
        let newInitContainer = try XCTUnwrap(sut.inspectablePhotoViewContainer())
        try await newInitContainer.completeImageDataLoading()
        XCTAssertEqual(loader.loggedPhotoIDs, [photo0.id, photo0.id], "Expect 2 photo data requests after photo view is initialised again")
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
        
        let container = try XCTUnwrap(sut.inspectablePhotoViewContainers().first)
        try await container.completeImageDataLoading()
        
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
        
        let containers = try sut.inspectablePhotoViewContainers()
        try containers[1].simulatePhotoViewInvisible()
        try await containers[0].completeImageDataLoading()
        try await containers[1].completeImageDataLoading()
        
        XCTAssertEqual(try containers[0].imageData(), imageData, "Expect image rendered on first view since it is visible")
        XCTAssertNil(try containers[1].imageData(), "Expect no image rendered on second view since it is invisible")
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
        
        let container = try XCTUnwrap(sut.inspectablePhotoViewContainer())
        try await container.completeImageDataLoading()
        XCTAssertNil(try container.imageData(), "Expect no image rendered on photo view when photo image request completed with error")
        
        try container.simulatePhotoViewVisible()
        try await container.completeImageDataLoading()
        XCTAssertEqual(try container.imageData(), imageData, "Expect image rendered on photo view when photo image re-request completed with image data successfully")
    }
    
    @MainActor
    func test_loadMorePhotos_rendersMorePhotoViewsWhenNextPageLoadingCompleted() async throws {
        let photo0 = makePhoto(id: "0", author: "author0")
        let photo1 = makePhoto(id: "1", author: "author1")
        let photo2 = makePhoto(id: "2", author: "author2")
        let imageData0 = UIImage.makeData(withColor: .red)
        let imageData1 = UIImage.makeData(withColor: .green)
        let imageData2 = UIImage.makeData(withColor: .blue)
        let (sut, _) = makeSUT(
            photoStubs: [.success([photo0]), .success([photo1]), .success([photo2])],
            dataStubs: [.success(imageData0), .success(imageData1), .success(imageData2)]
        )
        
        sut.simulateUserInitiateReload()
        await sut.completePhotosLoading()
        
        var containers = try sut.inspectablePhotoViewContainers()
        try await containers[0].completeImageDataLoading()
        XCTAssertEqual(containers.count, 1)
        XCTAssertEqual(try containers[0].imageData(), imageData0)
        
        await sut.completeLoadMorePhotos()
        
        containers = try sut.inspectablePhotoViewContainers()
        try await containers[1].completeImageDataLoading()
        XCTAssertEqual(containers.count, 2)
        XCTAssertEqual(try containers[0].imageData(), imageData0)
        XCTAssertEqual(try containers[1].imageData(), imageData1)
        
        await sut.completeLoadMorePhotos()
        
        containers = try sut.inspectablePhotoViewContainers()
        try await containers[2].completeImageDataLoading()
        XCTAssertEqual(containers.count, 3)
        XCTAssertEqual(try containers[0].imageData(), imageData0)
        XCTAssertEqual(try containers[1].imageData(), imageData1)
        XCTAssertEqual(try containers[2].imageData(), imageData2)
    }
    
    @MainActor
    func test_photoViewSelection_showsDetailViewWhilePhotoViewIsSelected() async throws {
        let photo0 = makePhoto(id: "0", author: "author0")
        let selectedPhoto = makePhoto(id: "1", author: "selected author")
        let (sut, _) = makeSUT(
            photoStubs: [.success([photo0, selectedPhoto])],
            dataStubs: [anySuccessData(), anySuccessData()],
            detailView: { _ in DummyDetailView() }
        )
        
        await sut.completePhotosLoading()
        
        XCTAssertFalse(sut.isShowingDetailView)
        
        sut.select(selectedPhoto)

        XCTAssertTrue(sut.isShowingDetailView)
    }
    
    // MARK: - Error view tests
    
    @MainActor
    func test_errorView_showsWhenPhotoRequestOnError() async throws {
        let (sut, _) = makeSUT(photoStubs: [anyFailure()])
        
        await sut.completePhotosLoading()
        
        let errorView = try XCTUnwrap(sut.errorView())
        XCTAssertEqual(try errorView.titleText(), PhotoGridStore.errorTitle)
        XCTAssertEqual(try errorView.messageText(), PhotoListViewModel.errorMessage)
        let cancelButton = try XCTUnwrap(errorView.actionButton())
        XCTAssertEqual(try cancelButton.role(), .cancel)
        
        try cancelButton.tap()
        XCTAssertNil(try? sut.errorView(), "Expect no error view is shown after cancel button tap")
    }
    
    @MainActor
    func test_errorView_showsWhenLoadMorePhotoRequestOnError() async throws {
        let photo = makePhoto()
        let (sut, _) = makeSUT(photoStubs: [.success([photo])], dataStubs: [anySuccessData()])
        
        await sut.completePhotosLoading()
        let container = try XCTUnwrap(sut.inspectablePhotoViewContainers().first)
        try await container.completeImageDataLoading()
        
        await sut.completeLoadMorePhotos()
        
        let errorView = try XCTUnwrap(sut.errorView())
        XCTAssertEqual(try errorView.titleText(), PhotoGridStore.errorTitle)
        XCTAssertEqual(try errorView.messageText(), PhotoListViewModel.errorMessage)
        let cancelButton = try XCTUnwrap(errorView.actionButton())
        XCTAssertEqual(try cancelButton.role(), .cancel)
        
        try cancelButton.tap()
        XCTAssertNil(try? sut.errorView(), "Expect no error view is shown after cancel button tap")
    }
    
    // MARK: - Helpers
    
    private typealias SUT = PhotoGridView<PhotoGridItemContainer, DummyDetailView>
    
    private func makeSUT(photoStubs: [PhotosLoaderSpy.PhotosResult] = [],
                         dataStubs: [PhotosLoaderSpy.DataResult] = [],
                         detailView: @escaping (Photo) -> DummyDetailView = { _ in DummyDetailView() },
                         function: String = #function,
                         file: StaticString = #file,
                         line: UInt = #line) -> (sut: SUT, loader: PhotosLoaderSpy) {
        let loader = PhotosLoaderSpy(photoStubs: photoStubs, dataStubs: dataStubs)
        let sut = PhotoGridComposer.composeWith(
            photosLoader: loader,
            imageLoader: loader,
            nextView: detailView
        )
        ViewHosting.host(view: sut, function: function)
        trackMemoryLeaks(for: loader, sut: sut, function: function, file: file, line: line)
        return (sut, loader)
    }
    
    private func trackMemoryLeaks(for instance: AnyObject,
                                  sut: SUT,
                                  function: String = #function,
                                  file: StaticString = #file,
                                  line: UInt = #line) {
        addTeardownBlock { [weak instance, weak self] in
            self?.dismissErrorView(on: sut)
            ViewHosting.expel(function: function)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                XCTAssertNil(
                    instance,
                    "Instance should have been deallocated. Potential memory leak.",
                    file: file,
                    line: line
                )
            }
        }
    }
    
    private func dismissErrorView(on sut: SUT) {
        let errorView = try? sut.errorView()
        try? errorView?.actionButton().tap()
        try? errorView?.dismiss()
    }
    
    private func assertThat(_ photoViews: [PhotoGridItem],
                            isRendering photos: [Photo],
                            file: StaticString = #file,
                            line: UInt = #line) throws {
        guard photos.count == photoViews.count else {
            XCTFail("Expect \(photos.count) photo views, got \(photoViews.count) instead", file: file, line: line)
            return
        }
        
        for i in 0..<photos.count {
            try assertThat(photoViews[i], hasViewConfigureFor: photos[i], at: i, file: file, line: line)
        }
    }
    
    private func assertThat(_ photoView: PhotoGridItem,
                            hasViewConfigureFor photo: Photo,
                            at index: Int,
                            file: StaticString = #file,
                            line: UInt = #line) throws {
        XCTAssertEqual(
            try photoView.authorText(),
            photo.author,
            "Expect author: \(photo.author) for index \(index)",
            file: file,
            line: line
        )
    }
}
