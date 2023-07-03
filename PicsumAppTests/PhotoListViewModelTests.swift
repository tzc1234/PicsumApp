//
//  PhotoListViewModelTests.swift
//  PicsumAppTests
//
//  Created by Tsz-Lung on 03/07/2023.
//

import XCTest
@testable import PicsumApp

struct Photo: Equatable {
    
}

protocol PhotosLoader {
    func load() async throws -> [Photo]
}

class PhotoListViewModel {
    var didLoad: (([Photo]) -> ())?
    
    init(loader: PhotosLoader) {
        
    }
    
    func load() {
        
    }
}

final class PhotoListViewModelTests: XCTestCase {
    
    func test_init_withoutTriggerLoader() {
        let (_, loader) = makeSUT()
        
        XCTAssertEqual(loader.stubs.count, 0)
    }
    
    func test_load_deliversEmptyPhotosOnError() {
        let (sut, _) = makeSUT(stubs: [.failure(anyNSError())])
        
        var photos = [Photo]()
        sut.didLoad = { photos = $0 }
        
        sut.load()
        
        XCTAssertEqual(photos, [])
    }
    
    func test_load_deliversEmptyPhotosWhenReceivedEmpty() {
        let (sut, _) = makeSUT(stubs: [.success([])])
        
        var photos = [Photo]()
        sut.didLoad = { photos = $0 }
        
        sut.load()
        
        XCTAssertEqual(photos, [])
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
