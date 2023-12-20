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
        return { [weak self] in
            guard let self else { return .empty }
            
            let photos = try await self.loader.load(page: page)
            let hasLoadMore = !photos.isEmpty
            return Paginated(items: photos, loadMore: hasLoadMore ? self.makePaginatedPhotos(page: page+1) : nil)
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
        let (sut, _) = makeSUT(photoStubs: [.failure(loaderError)])
        
        let getPaginatedPhotos = sut.makePaginatedPhotos()
        
        do {
            _ = try await getPaginatedPhotos()
            
            XCTFail("Expect an error")
        } catch {
            XCTAssertEqual(error as NSError, loaderError)
        }
    }
    
    func test_makePaginatedPhotos_requestsFromLoader() async throws {
        let anySuccessPhotos = PhotosLoaderSpy.PhotosResult.success([])
        let (sut, loader) = makeSUT(photoStubs: [anySuccessPhotos])
        let page = 999
        
        let getPaginatedPhotos = sut.makePaginatedPhotos(page: page)
        _ = try await getPaginatedPhotos()
        
        XCTAssertEqual(loader.loggedPages, [page])
    }
    
    func test_makePaginatedPhotos_convertsToPaginatedPhotosWithEmptyLoadMoreFromEmptyPhotos() async throws {
        let emptyPhotos = [Photo]()
        let (sut, _) = makeSUT(photoStubs: [.success(emptyPhotos)])
        
        let getPaginatedPhotos = sut.makePaginatedPhotos()
        let paginated = try await getPaginatedPhotos()
        
        XCTAssertEqual(paginated.items, emptyPhotos)
        XCTAssertNil(paginated.loadMore)
    }
    
    func test_makePaginatedPhotos_convertsToPaginatedPhotosWithLoadMoreFromNonEmptyPhotos() async throws {
        let photos = [makePhoto()]
        let (sut, _) = makeSUT(photoStubs: [.success(photos)])
        
        let getPaginatedPhotos = sut.makePaginatedPhotos()
        let paginated = try await getPaginatedPhotos()
        
        XCTAssertEqual(paginated.items, photos)
        XCTAssertNotNil(paginated.loadMore)
    }
    
    func test_paginatedPhotos_requestsLoadMoreFromLoader() async throws {
        let firstPage = 1
        let nextPage = firstPage + 1
        let firstPagePhotos = [makePhoto(id: "0")]
        let morePagePhotos = [makePhoto(id: "1")]
        let (sut, loader) = makeSUT(photoStubs: [.success(firstPagePhotos), .success(morePagePhotos)])
        
        let firstPaginatedPhotos = sut.makePaginatedPhotos(page: firstPage)
        let firstPaginated = try await firstPaginatedPhotos()
        
        XCTAssertEqual(firstPaginated.items, firstPagePhotos)
        XCTAssertEqual(loader.loggedPages, [firstPage], "Expect 1 page logged after the 1st request")
        
        let morePaginatedPhotos = try XCTUnwrap(firstPaginated.loadMore)
        let morePaginated = try await morePaginatedPhotos()
        
        XCTAssertEqual(morePaginated.items, morePagePhotos)
        XCTAssertEqual(loader.loggedPages, [firstPage, nextPage], "Expect 2 pages logged after the load more request")
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
