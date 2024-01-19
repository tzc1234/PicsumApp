//
//  PhotoDetailContainerIntegrationTests.swift
//  PicsumAppTests
//
//  Created by Tsz-Lung on 19/01/2024.
//

import XCTest
import ViewInspector
@testable import PicsumApp

final class PhotoDetailContainerIntegrationTests: XCTestCase {
    func test_detailView_rendersPhotoDetailCorrectly() throws {
        let photo = makePhoto(author: "author0", webURL: URL(string: "https://web0-url.com")!)
        let (sut, _) = makeSUT(photo: photo, dataStubs: [anySuccessData()])
        
        try assertThat(sut, hasConfigureFor: photo)
    }
    
    @MainActor
    func test_detailView_requestsPhotoImageForURL() async {
        let photo = makePhoto(url: URL(string: "https://image-url.com")!)
        let (sut, loader) = makeSUT(photo: photo, dataStubs: [anySuccessData()])
        
        await sut.completePhotoImageLoading()
        
        XCTAssertEqual(loader.loggedURLs, [photo.url])
    }
    
    @MainActor
    func test_detailView_doesNotRenderPhotoImageOnLoaderError() async throws {
        let (sut, _) = makeSUT(photo: makePhoto(), dataStubs: [anyFailure()])
        
        await sut.completePhotoImageLoading()
        
        try XCTAssertNil(sut.imageData())
    }
    
    @MainActor
    func test_detailView_rendersPhotoImageOnLoaderSuccess() async throws {
        let imageData = UIImage.makeData(withColor: .red)
        let (sut, _) = makeSUT(photo: makePhoto(), dataStubs: [.success(imageData)])
        
        await sut.completePhotoImageLoading()
        
        try XCTAssertEqual(sut.imageData(), imageData)
    }
    
    @MainActor
    func test_loadingIndicator_showsWhenLoadingPhotoImage() async throws {
        let (sut, _) = makeSUT(photo: makePhoto(), dataStubs: [anySuccessData()])
        
        XCTAssertTrue(sut.isShowingLoadingIndicator)
        
        await sut.completePhotoImageLoading()
        
        XCTAssertFalse(sut.isShowingLoadingIndicator)
    }
    
    @MainActor
    func test_reloadIndicator_showsWhenLoadingPhotoImageFailure() async throws {
        let (sut, _) = makeSUT(photo: makePhoto(), dataStubs: [anyFailure()])
        
        XCTAssertFalse(try sut.isShowingReloadIndicator())
        
        await sut.completePhotoImageLoading()
        
        XCTAssertTrue(try sut.isShowingReloadIndicator())
    }
    
    @MainActor
    func test_reloadPhotoImage_requestsPhotoImageAgainWhenUserInitiatedReload() async throws {
        let photo = makePhoto(url: URL(string: "https://image-url.com")!)
        let (sut, loader) = makeSUT(photo: photo, dataStubs: [anyFailure(), anyFailure()])
        
        await sut.completePhotoImageLoading()
        
        XCTAssertEqual(loader.loggedURLs, [photo.url], "Expect one photo image request after view rendered")
        
        try sut.simulateUserInitiateReload()
        await sut.completePhotoImageLoading()
        
        XCTAssertEqual(loader.loggedURLs, [photo.url, photo.url], "Expect one more photo image request after user initiate reload")
    }
    
    // MARK: - Helpers
    
    private func makeSUT(photo: Photo,
                         dataStubs: [PhotosLoaderSpy.DataResult] = [],
                         function: String = #function,
                         file: StaticString = #filePath,
                         line: UInt = #line) -> (sut: PhotoDetailContainer, loader: LoaderSpy) {
        let loader = LoaderSpy(dataStubs: dataStubs)
        let sut = PhotoDetailContainerComposer.composeWith(photo: photo, imageDataLoader: loader)
        ViewHosting.host(view: sut, function: function)
        trackMemoryLeaks(for: loader, function: function, file: file, line: line)
        return (sut, loader)
    }
    
    private func trackMemoryLeaks(for instance: AnyObject,
                                  function: String = #function,
                                  file: StaticString = #file,
                                  line: UInt = #line) {
        addTeardownBlock { [weak instance] in
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
    
    private func assertThat(_ sut: PhotoDetailContainer, 
                            hasConfigureFor photo: Photo,
                            file: StaticString = #filePath,
                            line: UInt = #line) throws {
        XCTAssertEqual(try sut.authorText(), photo.author, file: file, line: line)
        XCTAssertEqual(try sut.webURL(), photo.webURL, file: file, line: line)
    }
    
    private func anySuccessData() -> Result<Data, Error> {
        .success(anyData())
    }
    
    private func anyFailure() -> Result<Data, Error> {
        .failure(anyNSError())
    }
    
    private class LoaderSpy: ImageDataLoader {
        typealias DataResult = Swift.Result<Data, Error>
        
        private(set) var dataStubs: [DataResult]
        private(set) var loggedURLs = [URL]()
        
        init(dataStubs: [DataResult]) {
            self.dataStubs = dataStubs
        }
        
        func loadImageData(for url: URL) async throws -> Data {
            loggedURLs.append(url)
            return try dataStubs.removeFirst().get()
        }
    }
}

extension PhotoDetailContainer {
    func authorText() throws -> String {
        try inspect()
            .find(viewWithAccessibilityIdentifier: "photo-detail-author")
            .text()
            .string()
    }
    
    func webURL() throws -> URL {
        try inspect()
            .find(viewWithAccessibilityIdentifier: "photo-detail-link")
            .link()
            .url()
    }
    
    func imageData() throws -> Data? {
        try inspect()
            .find(viewWithAccessibilityIdentifier: "photo-detail-image")
            .image()
            .actualImage()
            .uiImage().pngData()
    }
    
    func completePhotoImageLoading() async {
        await store.delegate.task?.value
    }
    
    var isShowingLoadingIndicator: Bool {
        let shimmer = try? inspect()
            .find(viewWithAccessibilityIdentifier: "photo-detail-image-stack")
            .modifier(Shimmer.self)
        return shimmer != nil
    }
    
    func isShowingReloadIndicator() throws -> Bool {
        try reloadIndicator().opacity() > 0
    }
    
    func simulateUserInitiateReload() throws {
        try reloadIndicator().tap()
    }
    
    private func reloadIndicator() throws -> InspectableView<ViewType.Button> {
        try inspect().find(viewWithAccessibilityIdentifier: "photo-detail-reload-button").button()
    }
}
