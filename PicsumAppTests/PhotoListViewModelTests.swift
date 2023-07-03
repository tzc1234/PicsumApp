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
        
        var photos = [Photo]()
        sut.didLoad = { photos = $0 }
        
        await sut.load()
        
        XCTAssertEqual(photos, [])
    }
    
    func test_load_deliversEmptyPhotosWhenReceivedEmpty() async {
        let (sut, _) = makeSUT(stubs: [.success([])])
        
        var photos = [Photo]()
        sut.didLoad = { photos = $0 }
        
        await sut.load()
        
        XCTAssertEqual(photos, [])
    }
    
    func test_load_deliversOnePhotoWhenRecivedOne() async {
        let photo = makePhoto()
        let (sut, _) = makeSUT(stubs: [.success([photo])])
        
        var photos = [Photo]()
        sut.didLoad = { photos = $0 }
        
        await sut.load()
        
        XCTAssertEqual(photos, [photo])
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
