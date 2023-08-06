//
//  PhotoImageDataLoaderAdapterTests.swift
//  PicsumAppTests
//
//  Created by Tsz-Lung on 10/07/2023.
//

import XCTest
@testable import PicsumApp

final class PhotoImageDataLoaderAdapterTests: XCTestCase {

    func test_init_doesNotTriggerLoader() {
        let (_, loader) = makeSUT()
        
        XCTAssertEqual(loader.loggedURLs.count, 0)
    }
    
    func test_loadImageData_passesCorrectURLToLoader() async {
        let (sut, loader) = makeSUT(stubs: [.failure(anyNSError())])
        let id = "99"
        let width = 100
        let height = 200
        
        _ = try? await sut.loadImageData(by: id, width: width, height: height)
        
        let expectedURL = PhotoImageEndpoint.get(id: id, width: width, height: height).url
        XCTAssertEqual(loader.loggedURLs, [expectedURL])
    }
    
    func test_loadImageData_deliversErrorOnError() async {
        let (sut, _) = makeSUT(stubs: [.failure(anyNSError())])
        
        await asyncAssertThrowsError(_ = try await sut.loadImageData(by: "1", width: 1, height: 1))
    }
    
    func test_loadImageData_deliversDataOnSuccess() async throws {
        let data = anyData()
        let (sut, _) = makeSUT(stubs: [.success(data)])
        
        let receivedData = try await sut.loadImageData(by: "1", width: 1, height: 1)
        
        XCTAssertEqual(receivedData, data)
    }

    // MARK: - Helpers
    
    private func makeSUT(stubs: [ImageDataLoaderSpy.Stub] = [],
                         file: StaticString = #filePath,
                         line: UInt = #line) -> (sut: PhotoImageDataLoaderAdapter, loader: ImageDataLoaderSpy) {
        let loader = ImageDataLoaderSpy(stubs: stubs)
        let sut = PhotoImageDataLoaderAdapter(imageDataLoader: loader)
        
        trackForMemoryLeaks(loader, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        
        return (sut, loader)
    }

}
