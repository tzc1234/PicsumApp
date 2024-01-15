//
//  PhotoGridIntegrationTests.swift
//  PicsumAppTests
//
//  Created by Tsz-Lung on 15/01/2024.
//

import XCTest
import ViewInspector
@testable import PicsumApp

final class PhotoGridIntegrationTests: XCTestCase {
    func test_init_doesNotTriggerLoader() {
        let (_, loader) = makeSUT()
        
        XCTAssertTrue(loader.loggedURLs.isEmpty)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(photoStubs: [PhotosLoaderSpy.PhotosResult] = [],
                         dataStubs: [PhotosLoaderSpy.DataResult] = [],
                         selection: @escaping (Photo) -> Void = { _ in },
                         file: StaticString = #file,
                         line: UInt = #line) -> (sut: PhotoGridView, loader: PhotosLoaderSpy) {
        let loader = PhotosLoaderSpy(photoStubs: photoStubs, dataStubs: dataStubs)
        let sut = PhotoGridComposer.composeWith(photosLoader: loader)
        
        trackForMemoryLeaks(loader, file: file, line: line)
        
        return (sut, loader)
    }
}
