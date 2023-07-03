//
//  PhotoListViewModelTests.swift
//  PicsumAppTests
//
//  Created by Tsz-Lung on 03/07/2023.
//

import XCTest
@testable import PicsumApp

struct Photo: Equatable {
    let id, author: String
    let width, height: Int
    let webURL, url: URL
}

protocol PhotosLoader {
    func load() async throws -> [Photo]
}

class PhotoListViewModel {
    var didLoad: (([Photo]) -> ())?
     
    private let loader: PhotosLoader
    
    init(loader: PhotosLoader) {
        self.loader = loader
    }
    
    func load() async {
        do {
            let photos = try await loader.load()
            didLoad?(photos)
        } catch {
            
        }
    }
}

final class PhotoListViewModelTests: XCTestCase {
    
    func test_init_withoutTriggerLoader() {
        let (_, loader) = makeSUT()
        
        XCTAssertEqual(loader.stubs.count, 0)
    }
    
    func test_load_deliversEmptyPhotosOnError() async {
        let (sut, _) = makeSUT(stubs: [.failure(anyNSError())])
        
        await expect(sut, withExpectedPhotos: [], when: {
            await sut.load()
        })
    }
    
    func test_load_deliversEmptyPhotosWhenReceivedEmpty() async {
        let (sut, _) = makeSUT(stubs: [.success([])])
        
        await expect(sut, withExpectedPhotos: [], when: {
            await sut.load()
        })
    }
    
    func test_load_deliversOnePhotoWhenRecivedOne() async {
        let photo = makePhoto()
        let (sut, _) = makeSUT(stubs: [.success([photo])])
        
        await expect(sut, withExpectedPhotos: [photo], when: {
            await sut.load()
        })
    }
    
    func test_load_deliversMultiplePhotosWhenReceivedMultiples() async {
        let photos = [
            makePhoto(id: "id0", author: "author0", webURL: URL(string: "https://web0-url.com")!, URL: URL(string: "https://url0.com")!),
            makePhoto(id: "id1", author: "author1", webURL: URL(string: "https://web1-url.com")!, URL: URL(string: "https://url1.com")!),
            makePhoto(id: "id2", author: "author2", webURL: URL(string: "https://web2-url.com")!, URL: URL(string: "https://url2.com")!)
        ]
        let (sut, _) = makeSUT(stubs: [.success(photos)])
        
        await expect(sut, withExpectedPhotos: photos, when: {
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
    
    private func expect(_ sut: PhotoListViewModel,
                        withExpectedPhotos expectedPhotos: [Photo],
                        when action: () async -> Void,
                        file: StaticString = #file,
                        line: UInt = #line) async {
        var photos = [Photo]()
        sut.didLoad = { photos = $0 }
        
        await action()
        
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
        private(set) var stubs: [Result]
        
        init(stubs: [Result]) {
            self.stubs = stubs
        }
        
        func load() async throws -> [Photo] {
            try stubs.removeFirst().get()
        }
    }
    
}
