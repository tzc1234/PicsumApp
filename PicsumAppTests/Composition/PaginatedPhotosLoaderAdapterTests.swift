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
    
    func makePaginatedPhotos(page: Int = 1) -> () async throws -> Paginated<Photo> {
        return {
            let photos = try await self.loader.load(page: page)
            let hasLoadMore = !photos.isEmpty
            
            return Paginated(items: photos, loadMore: hasLoadMore ? self.makePaginatedPhotos() : nil)
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
            _ = try await getPaginatedPhotos()
            
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
        _ = try await getPaginatedPhotos()
        
        XCTAssertEqual(loader.loggedPages, [page])
    }
    
    func test_makePaginatedPhotos_convertsToPaginatedPhotosWithEmptyLoadMoreFromEmptyPhotos() async throws {
        let emptyPhotos = [Photo]()
        let (sut, loader) = makeSUT(photoStubs: [.success(emptyPhotos)])
        
        let getPaginatedPhotos = sut.makePaginatedPhotos()
        let paginated = try await getPaginatedPhotos()
        
        XCTAssertEqual(paginated.items, emptyPhotos)
        XCTAssertNil(paginated.loadMore)
    }
    
    func test_makePaginatedPhotos_convertsToPaginatedPhotosWithLoadMoreFromNonEmptyPhotos() async throws {
        let photos = [makePhoto()]
        let (sut, loader) = makeSUT(photoStubs: [.success(photos)])
        
        let getPaginatedPhotos = sut.makePaginatedPhotos()
        let paginated = try await getPaginatedPhotos()
        
        XCTAssertEqual(paginated.items, photos)
        XCTAssertNotNil(paginated.loadMore)
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
