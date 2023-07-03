//
//  PhotoListViewModelTests.swift
//  PicsumAppTests
//
//  Created by Tsz-Lung on 03/07/2023.
//

import XCTest
@testable import PicsumApp

final class PhotoListViewModelTests: XCTestCase {
    
    func test_init_withoutTriggerLoader() {
        let (_, loader) = makeSUT()
        
        XCTAssertEqual(loader.loggedPages.count, 0)
    }
    
    func test_load_deliversEmptyPhotosAndErrorMessageOnError() async {
        let (sut, loader) = makeSUT(stubs: [.failure(anyNSError())])
        
        await expect(sut, loader: loader, expectedError: PhotoListViewModel.errorMessage, when: {
            await sut.load()
        })
        XCTAssertEqual(loader.loggedPages, [1])
    }
    
    func test_load_deliversEmptyPhotosWhenReceivedEmpty() async {
        let (sut, loader) = makeSUT(stubs: [.success([])])
        
        await expect(sut, loader: loader, expectedPhotos: [], when: {
            await sut.load()
        })
        XCTAssertEqual(loader.loggedPages, [1])
    }
    
    func test_load_deliversOnePhotoWhenRecivedOne() async {
        let photos = [makePhoto()]
        let (sut, loader) = makeSUT(stubs: [.success(photos)])
        
        await expect(sut, loader: loader, expectedPhotos: photos, when: {
            await sut.load()
        })
        XCTAssertEqual(loader.loggedPages, [1])
    }
    
    func test_load_deliversMultiplePhotosWhenReceivedMultiples() async {
        let photos = [
            makePhoto(id: "id0"),
            makePhoto(id: "id1"),
            makePhoto(id: "id2")
        ]
        let (sut, loader) = makeSUT(stubs: [.success(photos)])
        
        await expect(sut, loader: loader, expectedPhotos: photos, when: {
            await sut.load()
        })
        XCTAssertEqual(loader.loggedPages, [1])
    }
    
    func test_loadMore_deliversErrorMessageWhenOnError() async {
        let photoSet0 = [makePhoto(id: "id0")]
        let photoSet1 = [makePhoto(id: "id1")]
        let (sut, loader) = makeSUT(stubs: [.success(photoSet0), .failure(anyNSError()), .success(photoSet1)])
        
        await expect(sut, loader: loader, expectedPhotos: photoSet0, when: {
            await sut.load()
        })
        
        await expect(sut, loader: loader, expectedError: PhotoListViewModel.errorMessage, when: {
            await sut.loadMore()
        })
        
        await expect(sut, loader: loader, expectedPhotos: photoSet0 + photoSet1, when: {
            await sut.loadMore()
        })
        XCTAssertEqual(loader.loggedPages, [1, 2, 2])
    }
    
    func test_loadMore_deliversMorePhotosWhenSuccess() async {
        let photoSet0 = [makePhoto(id: "id0"), makePhoto(id: "id1")]
        let photoSet1 = [makePhoto(id: "id2"), makePhoto(id: "id3")]
        let photoSet2 = [makePhoto(id: "id4")]
        let (sut, loader) = makeSUT(stubs: [.success(photoSet0), .success(photoSet1), .success(photoSet2)])
        
        await expect(sut, loader: loader, expectedPhotos: photoSet0, when: {
            await sut.load()
        })
        
        await expect(sut, loader: loader, expectedPhotos: photoSet0 + photoSet1, when: {
            await sut.loadMore()
        })
        
        await expect(sut, loader: loader, expectedPhotos: photoSet0 + photoSet1 + photoSet2, when: {
            await sut.loadMore()
        })
        XCTAssertEqual(loader.loggedPages, [1, 2, 3])
    }
    
    func test_loadMore_deliversFromTheFirstSetPhotosAgainWhenTriggersLoadAgain() async {
        let photoSet0 = [makePhoto(id: "id0"), makePhoto(id: "id1")]
        let photoSet1 = [makePhoto(id: "id2"), makePhoto(id: "id3")]
        let (sut, loader) = makeSUT(stubs: [.success(photoSet0), .success(photoSet1), .success(photoSet0), .success(photoSet1)])
        
        await expect(sut, loader: loader, expectedPhotos: photoSet0, when: {
            await sut.load()
        })
        
        await expect(sut, loader: loader, expectedPhotos: photoSet0 + photoSet1, when: {
            await sut.loadMore()
        })
        
        await expect(sut, loader: loader, expectedPhotos: photoSet0, when: {
            await sut.load()
        })
        
        await expect(sut, loader: loader, expectedPhotos: photoSet0 + photoSet1, when: {
            await sut.loadMore()
        })
        XCTAssertEqual(loader.loggedPages, [1, 2, 1, 2])
    }
    
    func test_loadMore_stopLoadMoreAgainWhenReceivedEmptyPhotosFromLoadMore() async {
        let photoSet = [makePhoto(id: "id0"), makePhoto(id: "id1")]
        let (sut, loader) = makeSUT(stubs: [.success(photoSet), .success([])])
        
        await sut.load()
        await sut.loadMore()
        await sut.loadMore()
        XCTAssertEqual(loader.loggedPages, [1, 2])
    }
    
    func test_loadMore_stopLoadMoreAgainWhenReceivedEmptyPhotosFromLoad() async {
        let (sut, loader) = makeSUT(stubs: [.success([])])
        
        await sut.load()
        await sut.loadMore()
        XCTAssertEqual(loader.loggedPages, [1])
    }

    // MARK: - Helpers
    
    private typealias Result = Swift.Result<[Photo], Error>
    
    private func makeSUT(stubs: [Result] = [],
                         file: StaticString = #file,
                         line: UInt = #line) -> (sut: PhotoListViewModel, loader: LoaderSpy) {
        let loader = LoaderSpy(stubs: stubs)
        let sut = PhotoListViewModel(loader: loader)
        
        trackForMemoryLeaks(loader, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        
        return (sut, loader)
    }
    
    private func expect(_ sut: PhotoListViewModel, loader: LoaderSpy,
                        expectedError: String? = nil, expectedPhotos: [Photo]? = nil,
                        when action: () async -> Void, file: StaticString = #file,
                        line: UInt = #line) async {
        var isLoading: Bool?
        sut.onLoad = { isLoading = $0 }
        
        var errorMessage: String?
        sut.onError = { errorMessage = $0 }
        
        var photos: [Photo]?
        sut.didLoad = { photos = $0 }
        
        loader.beforeLoad = {
            XCTAssertEqual(isLoading, true, "Expect start loading", file: file, line: line)
            XCTAssertNil(errorMessage, "Expect nil error message", file: file, line: line)
            XCTAssertNil(photos, "Expect nil photos", file: file, line: line)
        }
        
        await action()
        
        XCTAssertEqual(isLoading, false, "Expect end loading", file: file, line: line)
        XCTAssertEqual(errorMessage, expectedError, file: file, line: line)
        XCTAssertEqual(photos, expectedPhotos, file: file, line: line)
    }
    
    private func makePhoto(id: String = "any id", author: String = "any author",
                           width: Int = 1, height: Int = 1,
                           webURL: URL = URL(string: "https://any-web-url.com")!,
                           URL: URL = URL(string: "https://any-url.com")!) -> Photo {
        .init(id: id, author: author, width: width, height: height, webURL: webURL, url: URL)
    }
    
    private func anyNSError() -> NSError {
        NSError(domain: "error", code: 0)
    }
    
    private class LoaderSpy: PhotosLoader {
        var beforeLoad: (() -> Void)?
        private(set) var loggedPages = [Int]()
        
        private(set) var stubs: [Result]
        
        init(stubs: [Result]) {
            self.stubs = stubs
        }
        
        func load(page: Int) async throws -> [Photo] {
            beforeLoad?()
            loggedPages.append(page)
            return try stubs.removeFirst().get()
        }
    }
    
}
