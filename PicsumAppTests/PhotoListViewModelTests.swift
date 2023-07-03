//
//  PhotoListViewModelTests.swift
//  PicsumAppTests
//
//  Created by Tsz-Lung on 03/07/2023.
//

import XCTest
@testable import PicsumApp

class PhotoListViewModel {
    typealias Observer<T> = (T) -> Void
    
    var onLoad: Observer<Bool>?
    var onError: Observer<String>?
    var didLoad: Observer<[Photo]>?
     
    private let loader: PhotosLoader
    
    init(loader: PhotosLoader) {
        self.loader = loader
    }
    
    func load() async {
        onLoad?(true)
        
        do {
            let photos = try await loader.load(page: 1)
            didLoad?(photos)
        } catch {
            onError?(Self.errorMessage)
        }
        
        onLoad?(false)
    }
    
    func loadMore() async {
        onLoad?(true)
        
        do {
            _ = try await loader.load(page: 2)
        } catch {
            onError?(Self.errorMessage)
        }
        
        onLoad?(false)
    }
    
    static var errorMessage: String {
        "Error occured, please reload again."
    }
}

final class PhotoListViewModelTests: XCTestCase {
    
    func test_init_withoutTriggerLoader() {
        let (_, loader) = makeSUT()
        
        XCTAssertEqual(loader.loggedPages.count, 0)
    }
    
    func test_load_deliversEmptyPhotosAndErrorMessageOnError() async {
        let result = Result.failure(anyNSError())
        let (sut, loader) = makeSUT(stubs: [result])
        
        await expect(sut, loader: loader, withExpected: result, when: {
            await sut.load()
        })
    }
    
    func test_load_deliversEmptyPhotosWhenReceivedEmpty() async {
        let result = Result.success([])
        let (sut, loader) = makeSUT(stubs: [result])
        
        await expect(sut, loader: loader, withExpected: result, when: {
            await sut.load()
        })
    }
    
    func test_load_deliversOnePhotoWhenRecivedOne() async {
        let result = Result.success([makePhoto()])
        let (sut, loader) = makeSUT(stubs: [result])
        
        await expect(sut, loader: loader, withExpected: result, when: {
            await sut.load()
        })
    }
    
    func test_load_deliversMultiplePhotosWhenReceivedMultiples() async {
        let photos = [
            makePhoto(id: "id0"),
            makePhoto(id: "id1"),
            makePhoto(id: "id2")
        ]
        let result = Result.success(photos)
        let (sut, loader) = makeSUT(stubs: [result])
        
        await expect(sut, loader: loader, withExpected: result, when: {
            await sut.load()
        })
    }
    
    func test_loadMore_deliversErrorMessageWhenOnError() async {
        let successResult = Result.success([makePhoto()])
        let errorResult = Result.failure(anyNSError())
        let (sut, loader) = makeSUT(stubs: [successResult, errorResult])
        
        await expect(sut, loader: loader, withExpected: successResult, when: {
            await sut.load()
        })
        
        await expect(sut, loader: loader, withExpected: errorResult, when: {
            await sut.loadMore()
        })
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
                        withExpected result: Result,
                        when action: () async -> Void,
                        file: StaticString = #file,
                        line: UInt = #line) async {
        var isLoading: Bool?
        sut.onLoad = { isLoading = $0 }
        
        var errorMessage: String?
        sut.onError = { errorMessage = $0 }
        
        var photos = [Photo]()
        sut.didLoad = { photos = $0 }
        
        loader.beforeLoad = {
            XCTAssertEqual(isLoading, true, "Expect start loading", file: file, line: line)
            XCTAssertNil(errorMessage, "Expect no error message", file: file, line: line)
        }
        
        await action()
        
        XCTAssertEqual(isLoading, false, "Expect end loading", file: file, line: line)
        switch result {
        case let .success(expectedPhotos):
            XCTAssertEqual(photos, expectedPhotos, file: file, line: line)
        case .failure:
            XCTAssertEqual(errorMessage, PhotoListViewModel.errorMessage, file: file, line: line)
        }
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
