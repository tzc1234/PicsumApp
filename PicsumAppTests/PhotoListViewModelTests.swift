//
//  PhotoListViewModelTests.swift
//  PicsumAppTests
//
//  Created by Tsz-Lung on 03/07/2023.
//

import XCTest
@testable import PicsumApp

class PhotoListViewModel {
    var onLoad: ((Bool) -> Void)?
    var didLoad: (([Photo]) -> ())?
     
    private let loader: PhotosLoader
    
    init(loader: PhotosLoader) {
        self.loader = loader
    }
    
    func load() async {
        onLoad?(true)
        
        do {
            let photos = try await loader.load()
            didLoad?(photos)
        } catch {
            
        }
        
        onLoad?(false)
    }
}

final class PhotoListViewModelTests: XCTestCase {
    
    func test_init_withoutTriggerLoader() {
        let (_, loader) = makeSUT()
        
        XCTAssertEqual(loader.stubs.count, 0)
    }
    
    func test_load_deliversEmptyPhotosOnError() async {
        let (sut, loader) = makeSUT(stubs: [.failure(anyNSError())])
        
        await expect(sut, loader: loader, withExpectedPhotos: [], when: {
            await sut.load()
        })
    }
    
    func test_load_deliversEmptyPhotosWhenReceivedEmpty() async {
        let (sut, loader) = makeSUT(stubs: [.success([])])
        
        await expect(sut, loader: loader, withExpectedPhotos: [], when: {
            await sut.load()
        })
    }
    
    func test_load_deliversOnePhotoWhenRecivedOne() async {
        let photo = makePhoto()
        let (sut, loader) = makeSUT(stubs: [.success([photo])])
        
        await expect(sut, loader: loader, withExpectedPhotos: [photo], when: {
            await sut.load()
        })
    }
    
    func test_load_deliversMultiplePhotosWhenReceivedMultiples() async {
        let photos = [
            makePhoto(id: "id0", author: "author0", webURL: URL(string: "https://web0-url.com")!, URL: URL(string: "https://url0.com")!),
            makePhoto(id: "id1", author: "author1", webURL: URL(string: "https://web1-url.com")!, URL: URL(string: "https://url1.com")!),
            makePhoto(id: "id2", author: "author2", webURL: URL(string: "https://web2-url.com")!, URL: URL(string: "https://url2.com")!)
        ]
        let (sut, loader) = makeSUT(stubs: [.success(photos)])
        
        await expect(sut, loader: loader, withExpectedPhotos: photos, when: {
            await sut.load()
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
                        withExpectedPhotos expectedPhotos: [Photo],
                        when action: () async -> Void,
                        file: StaticString = #file,
                        line: UInt = #line) async {
        var photos = [Photo]()
        sut.didLoad = { photos = $0 }
        
        var isLoading: Bool?
        sut.onLoad = { isLoading = $0 }
        
        loader.beforeLoad = {
            XCTAssertEqual(isLoading, true, "Expect start loading", file: file, line: line)
        }
        
        await action()
        
        XCTAssertEqual(isLoading, false, "Expect end loading", file: file, line: line)
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
        
        private(set) var stubs: [Result]
        
        init(stubs: [Result]) {
            self.stubs = stubs
        }
        
        func load() async throws -> [Photo] {
            beforeLoad?()
            return try stubs.removeFirst().get()
        }
    }
    
}
