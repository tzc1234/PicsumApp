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
    
    func makePaginatedPhotos(page: Int = 1) -> () async throws -> Void {
        return {
            _ = try await self.loader.load(page: page)
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
    
    func test_makePaginatedPhotos_passesCorrectPageToLoader() async throws {
        let anySuccessPhotos = PhotosLoaderSpy.PhotosResult.success([])
        let (sut, loader) = makeSUT(photoStubs: [anySuccessPhotos])
        let page = 999
        
        let getPaginatedPhotos = sut.makePaginatedPhotos(page: page)
        try await getPaginatedPhotos()
        
        XCTAssertEqual(loader.loggedPages, [page])
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
