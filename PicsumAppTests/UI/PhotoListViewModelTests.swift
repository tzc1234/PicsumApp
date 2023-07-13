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
            await sut.loadPhotos()
        })
        XCTAssertEqual(loader.loggedPages, [1])
    }
    
    func test_load_deliversEmptyPhotosWhenReceivedEmpty() async {
        let (sut, loader) = makeSUT(stubs: [.success([]), .success([])])
        
        await expect(sut, loader: loader, expectedPhotos: [], when: {
            await sut.loadPhotos()
        })
        
        await expect(sut, loader: loader, expectedPhotos: [], when: {
            await sut.loadPhotos()
        })
        XCTAssertEqual(loader.loggedPages, [1, 1])
    }
    
    func test_load_deliversOnePhotoWhenRecivedOne() async {
        let photos = [makePhoto()]
        let (sut, loader) = makeSUT(stubs: [.success(photos)])
        
        await expect(sut, loader: loader, expectedPhotos: photos, when: {
            await sut.loadPhotos()
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
            await sut.loadPhotos()
        })
        XCTAssertEqual(loader.loggedPages, [1])
    }
    
    func test_loadMore_deliversUpdatedPhotosWhenLoadMoreAginAfterAnError() async {
        let photoSet0 = [makePhoto(id: "id0")]
        let photoSet1 = [makePhoto(id: "id1")]
        let (sut, loader) = makeSUT(stubs: [.success(photoSet0), .failure(anyNSError()), .success(photoSet1)])
        
        await expect(sut, loader: loader, expectedPhotos: photoSet0, when: {
            await sut.loadPhotos()
        })
        
        await expect(sut, loader: loader, expectedError: PhotoListViewModel.errorMessage, when: {
            await sut.loadMorePhotos()
        })
        
        await expect(sut, loader: loader, expectedPhotos: photoSet0 + photoSet1, when: {
            await sut.loadMorePhotos()
        })
        XCTAssertEqual(loader.loggedPages, [1, 2, 2])
    }
    
    func test_loadMore_deliversMorePhotosWhenSuccess() async {
        let photoSet0 = [makePhoto(id: "id0"), makePhoto(id: "id1")]
        let photoSet1 = [makePhoto(id: "id2"), makePhoto(id: "id3")]
        let photoSet2 = [makePhoto(id: "id4")]
        let (sut, loader) = makeSUT(stubs: [.success(photoSet0), .success(photoSet1), .success(photoSet2)])
        
        await expect(sut, loader: loader, expectedPhotos: photoSet0, when: {
            await sut.loadPhotos()
        })
        
        await expect(sut, loader: loader, expectedPhotos: photoSet0 + photoSet1, when: {
            await sut.loadMorePhotos()
        })
        
        await expect(sut, loader: loader, expectedPhotos: photoSet0 + photoSet1 + photoSet2, when: {
            await sut.loadMorePhotos()
        })
        XCTAssertEqual(loader.loggedPages, [1, 2, 3])
    }
    
    func test_loadMore_deliversFromTheFirstSetPhotosAgainWhenTriggersLoadAgain() async {
        let photoSet0 = [makePhoto(id: "id0"), makePhoto(id: "id1")]
        let photoSet1 = [makePhoto(id: "id2"), makePhoto(id: "id3")]
        let (sut, loader) = makeSUT(stubs: [.success(photoSet0), .success(photoSet1), .success(photoSet0), .success(photoSet1)])
        
        await expect(sut, loader: loader, expectedPhotos: photoSet0, when: {
            await sut.loadPhotos()
        })
        
        await expect(sut, loader: loader, expectedPhotos: photoSet0 + photoSet1, when: {
            await sut.loadMorePhotos()
        })
        
        await expect(sut, loader: loader, expectedPhotos: photoSet0, when: {
            await sut.loadPhotos()
        })
        
        await expect(sut, loader: loader, expectedPhotos: photoSet0 + photoSet1, when: {
            await sut.loadMorePhotos()
        })
        XCTAssertEqual(loader.loggedPages, [1, 2, 1, 2])
    }
    
    func test_loadMore_stopLoadMoreWhenReceivedEmptyPhotosFromLoadMore() async {
        let photoSet = [makePhoto(id: "id0"), makePhoto(id: "id1")]
        let (sut, loader) = makeSUT(stubs: [.success(photoSet), .success([])])
        
        await sut.loadPhotos()
        await sut.loadMorePhotos()
        await sut.loadMorePhotos()
        XCTAssertEqual(loader.loggedPages, [1, 2])
    }
    
    func test_loadMore_stopLoadMoreWhenReceivedEmptyPhotosFromLoad() async {
        let (sut, loader) = makeSUT(stubs: [.success([])])
        
        await sut.loadPhotos()
        await sut.loadMorePhotos()
        XCTAssertEqual(loader.loggedPages, [1])
    }
    
    func test_load_deliversNilErrorMessageWhenLoadSuccessAfterAnError() async {
        let (sut, _) = makeSUT(stubs: [.failure(anyNSError()), .success([])])
        
        var errorMessage: String?
        sut.onError = { errorMessage = $0 }
        
        await sut.loadPhotos()
        await sut.loadPhotos()
        
        XCTAssertNil(errorMessage)
    }
    
    func test_loadMore_deliversNilErrorMessageWhenLoadMoreSuccessAfterAnError() async {
        let (sut, _) = makeSUT(stubs: [.failure(anyNSError()), .success([])])
        
        var errorMessage: String?
        sut.onError = { errorMessage = $0 }
        
        await sut.loadMorePhotos()
        await sut.loadMorePhotos()
        
        XCTAssertNil(errorMessage)
    }

    // MARK: - Helpers
    
    private func makeSUT(stubs: [PhotosLoaderSpy.PhotosResult] = [],
                         file: StaticString = #file,
                         line: UInt = #line) -> (sut: PhotoListViewModel, loader: PhotosLoaderSpy) {
        let loader = PhotosLoaderSpy(photoStubs: stubs, dataStubs: [])
        let sut = PhotoListViewModel(loader: loader)
        
        trackForMemoryLeaks(loader, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        
        return (sut, loader)
    }
    
    private func expect(_ sut: PhotoListViewModel, loader: PhotosLoaderSpy,
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
    
}