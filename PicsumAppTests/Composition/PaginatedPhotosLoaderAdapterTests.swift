//
//  PaginatedPhotosLoaderAdapterTests.swift
//  PicsumAppTests
//
//  Created by Tsz-Lung on 20/12/2023.
//

import XCTest
@testable import PicsumApp

final class PaginatedPhotosLoaderAdapterTests: XCTestCase {
    func test_init_doesNotNotifyLoader() {
        let (_, loader) = makeSUT()
        
        XCTAssertTrue(loader.loggedURLs.isEmpty)
    }
    
    func test_makePaginatedPhotos_forwardsErrorFromLoaderError() async {
        let loaderError = NSError(domain: "loader error", code: 0)
        let (sut, _) = makeSUT(photoStubs: [.failure(loaderError)])
        
        do {
            _ = try await sut.makePaginatedPhotos()
            
            XCTFail("Expect an error")
        } catch {
            XCTAssertEqual(error as NSError, loaderError)
        }
    }
    
    func test_makePaginatedPhotos_requestsFromLoader() async throws {
        let anySuccessPhotos = PhotosLoaderSpy.PhotosResult.success([])
        let (sut, loader) = makeSUT(photoStubs: [anySuccessPhotos])
        let page = 999
        
        _ = try await sut.makePaginatedPhotos(page: page)
        
        XCTAssertEqual(loader.loggedURLs, [makeURL(for: page)])
    }
    
    func test_makePaginatedPhotos_convertsToPaginatedPhotosWithEmptyLoadMoreFromEmptyPhotos() async throws {
        let emptyPhotos = [Photo]()
        let (sut, _) = makeSUT(photoStubs: [.success(emptyPhotos)])
        
        let paginated = try await sut.makePaginatedPhotos()
        
        XCTAssertEqual(paginated.items, emptyPhotos)
        XCTAssertNil(paginated.loadMore)
    }
    
    func test_makePaginatedPhotos_convertsToPaginatedPhotosWithLoadMoreFromNonEmptyPhotos() async throws {
        let photos = [makePhoto()]
        let (sut, _) = makeSUT(photoStubs: [.success(photos)])
        
        let paginated = try await sut.makePaginatedPhotos()
        
        XCTAssertEqual(paginated.items, photos)
        XCTAssertNotNil(paginated.loadMore)
    }
    
    func test_paginatedPhotos_requestsLoadMoreFromLoader() async throws {
        let firstPage = 1
        let nextPage = firstPage + 1
        let firstPagePhotos = [makePhoto(id: "0")]
        let morePagePhotos = [makePhoto(id: "1")]
        let (sut, loader) = makeSUT(photoStubs: [.success(firstPagePhotos), .success(morePagePhotos)])
        
        let firstPaginated = try await sut.makePaginatedPhotos(page: firstPage)
        
        XCTAssertEqual(firstPaginated.items, firstPagePhotos)
        XCTAssertEqual(loader.loggedURLs, [makeURL(for: firstPage)], "Expect 1 page logged after the 1st request")
        
        let morePaginatedPhotos = try XCTUnwrap(firstPaginated.loadMore)
        let morePaginated = try await morePaginatedPhotos()
        
        XCTAssertEqual(morePaginated.items, morePagePhotos)
        XCTAssertEqual(
            loader.loggedURLs,
            [makeURL(for: firstPage), makeURL(for: nextPage)],
            "Expect 2 pages logged after the load more request"
        )
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
    
    private func makeURL(for page: Int) -> URL {
        PhotosEndpoint.get(page: page).url
    }
}
