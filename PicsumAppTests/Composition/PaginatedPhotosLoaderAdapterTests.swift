//
//  PaginatedPhotosLoaderAdapterTests.swift
//  PicsumAppTests
//
//  Created by Tsz-Lung on 20/12/2023.
//

import XCTest
@testable import PicsumApp

final class PaginatedPhotosLoaderAdapter {
    private let loader: PhotosLoader
    
    init(loader: PhotosLoader) {
        self.loader = loader
    }
    
    func makePaginatedPhotos() -> () async throws -> Void {
        return {
            _ = try await self.loader.load(page: 1)
        }
    }
}

final class PaginatedPhotosLoaderAdapterTests: XCTestCase {
    func test_init_doesNotNotifyLoader() {
        let (_, loader) = makeSUT()
        
        XCTAssertTrue(loader.loggedPages.isEmpty)
    }
    
    func test_makePaginatedPhotos_forwardsErrorFromLoaderError() async {
        let loaderError = NSError(domain: "loader error", code: 0)
        let (sut, loader) = makeSUT(photoStubs: [.failure(loaderError)])
        
        let getPaginatedPhotos = sut.makePaginatedPhotos()
        
        do {
            try await getPaginatedPhotos()
            
            XCTFail("Expect an error")
        } catch {
            XCTAssertEqual(error as NSError, loaderError)
        }
    }
    
    // MARK: - Helpers
    
    private func makeSUT(photoStubs: [PhotosLoaderSpy.PhotosResult] = [],
                         file: StaticString = #filePath,
                         line: UInt = #line) -> (sut: PaginatedPhotosLoaderAdapter, loader: PhotosLoaderSpy) {
        let loader = PhotosLoaderSpy(photoStubs: photoStubs)
        let sut = PaginatedPhotosLoaderAdapter(loader: loader)
        
        trackForMemoryLeaks(loader, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        
        return (sut, loader)
    }
}
