//
//  PhotoDetailIntegrationTests.swift
//  PicsumAppTests
//
//  Created by Tsz-Lung on 16/07/2023.
//

import XCTest
@testable import PicsumApp

final class PhotoDetailIntegrationTests: XCTestCase {

    func test_init_hasTitle() {
        let (sut, _) = makeSUT()

        XCTAssertEqual(sut.title, PhotoDetailViewModel<Any>.title)
    }
    
    @MainActor
    func test_detailView_rendersPhotoCorrectly() async {
        let photo = makePhoto(author: "author0", webURL: URL(string: "https://web0-url.com")!)
        let (sut, _) = makeSUT(photo: photo, dataStubs: [.success(anyData())])
        
        sut.layoutIfNeeded()
        await sut.completeTaskNow()
        
        assertThat(sut, hasConfiguredWith: photo)
    }
    
    @MainActor
    func test_detailView_requestsPhotoImageForURL() async {
        let photo = makePhoto(url: URL(string: "https://image-url.com")!)
        let (sut, loader) = makeSUT(photo: photo, dataStubs: [.success(anyData())])
        
        sut.simulatePhotoDetailViewWillAppear()
        await sut.completeTaskNow()
        
        XCTAssertEqual(loader.loggedURLs, [photo.url])
    }
    
    @MainActor
    func test_detailView_doesNotRenderPhotoImageOnLoaderError() async {
        let photo = makePhoto()
        let (sut, _) = makeSUT(photo: photo, dataStubs: [.failure(anyNSError())])
        
        sut.layoutIfNeeded()
        await sut.completeTaskNow()
        
        XCTAssertNil(sut.imageData)
    }
    
    @MainActor
    func test_detailView_renderPhotoImageOnLoaderSuccess() async {
        let photo = makePhoto()
        let imageData = UIImage.make(withColor: .red).pngData()!
        let (sut, _) = makeSUT(photo: photo, dataStubs: [.success(imageData)])
        
        sut.layoutIfNeeded()
        sut.simulatePhotoDetailViewWillAppear()
        await sut.completeTaskNow()
        
        XCTAssertEqual(sut.imageData, imageData)
    }
    
    @MainActor
    func test_detailViewLoadingIndicator_showsBeforeImageRequestCompleted() async {
        let imageData = UIImage.make(withColor: .red).pngData()!
        let (sut, _) = makeSUT(dataStubs: [.success(imageData)])
        
        sut.layoutIfNeeded()
        sut.simulatePhotoDetailViewWillAppear()
        
        XCTAssertTrue(sut.isShowingLoadingIndicator, "Expect a loading indicator once image request started")
        
        await sut.completeTaskNow()
        
        XCTAssertFalse(sut.isShowingLoadingIndicator, "Expect no loading indicator after image request completed")
        
        sut.simulatePhotoDetailViewWillAppear()
        
        XCTAssertFalse(sut.isShowingLoadingIndicator, "Expect no loading indicator after photo detail will appear again with image")
    }
    
    @MainActor
    func test_reloadIndicator_showsAfterImageRequestOnLoaderError() async {
        let (sut, _) = makeSUT(dataStubs: [.failure(anyNSError()), .success(anyData())])
        
        sut.layoutIfNeeded()
        sut.simulatePhotoDetailViewWillAppear()
        
        XCTAssertFalse(sut.isShowingReloadIndicator, "Expect no reload indicator once image request started")
        
        await sut.completeTaskNow()
        
        XCTAssertTrue(sut.isShowingReloadIndicator, "Expect a reload indicator after image request completed with error")
        
        sut.simulateUserInitiatedReload()
        
        XCTAssertFalse(sut.isShowingReloadIndicator, "Expect no reload indicator once image reload request started")
        
        await sut.completeTaskNow()
        
        XCTAssertFalse(sut.isShowingReloadIndicator, "Expect no reload indicator once image reload request completed successfully")
    }
    
    @MainActor
    func test_photoDetailWeb_showsForWebURL() async {
        var loggedURLs = [URL]()
        let photo = makePhoto(webURL: URL(string: "https://web0-url.com")!)
        let (sut, _) = makeSUT(photo: photo, urlHandler: { loggedURLs.append($0) })
        
        sut.layoutIfNeeded()
        sut.simulateUserOpenPhotoDetailWeb()
        
        XCTAssertEqual(loggedURLs, [photo.webURL])
    }

    // MARK: - Helpers
    
    private func makeSUT(photo: Photo = makePhoto(),
                         dataStubs: [PhotosLoaderSpy.DataResult] = [],
                         urlHandler: @escaping (URL) -> Void = { _ in },
                         file: StaticString = #filePath, line: UInt = #line) -> (sut: PhotoDetailViewController, loader: LoaderSpy) {
        let loader = LoaderSpy(dataStubs: dataStubs)
        let sut = PhotoDetailComposer.composeWith(photo: photo, imageDataLoader: loader, urlHandler: urlHandler)
        trackForMemoryLeaks(loader, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, loader)
    }
    
    private func assertThat(_ sut: PhotoDetailViewController, hasConfiguredWith photo: Photo,
                            file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(sut.authorText, photo.author,
                       "Expect author is \(photo.author), got \(String(describing: sut.authorText)) instead",
                       file: file, line: line)
        XCTAssertEqual(sut.webURLText, photo.webURL.absoluteString,
                       "Expect webURL is \(photo.webURL.absoluteString), got \(String(describing: sut.webURLText)) instead",
                       file: file, line: line)
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
