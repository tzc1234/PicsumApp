//
//  PhotoImageDataLoaderAdapterTests.swift
//  PicsumAppTests
//
//  Created by Tsz-Lung on 10/07/2023.
//

import XCTest
@testable import PicsumApp

class PhotoImageDataLoaderAdapter: PhotoImageDataLoader {
    private let loader: ImageDataLoader
    
    init(imageDataLoader: ImageDataLoader) {
        self.loader = imageDataLoader
    }
    
    func loadImageData(by id: String, width: Int, height: Int) async throws -> Data {
        let url = PhotoImageEndpoint.get(id: id, width: width, height: height).url
        _ = try? await loader.loadImageData(for: url)
        throw anyNSError()
    }
}

final class PhotoImageDataLoaderAdapterTests: XCTestCase {

    func test_init_noTriggerLoader() {
        let (_, loader) = makeSUT()
        
        XCTAssertEqual(loader.loggedURLs.count, 0)
    }
    
    func test_loadImageData_passesCorrectURLToLoader() async {
        let (sut, loader) = makeSUT()
        let id = "99"
        let width = 100
        let height = 200
        
        _ = try? await sut.loadImageData(by: id, width: width, height: height)
        
        let expectedURL = PhotoImageEndpoint.get(id: id, width: width, height: height).url
        XCTAssertEqual(loader.loggedURLs, [expectedURL])
    }

    // MARK: - Helpers
    
    private func makeSUT(stubs: [RemoteImageDataLoaderSpy.Stub] = [],
                         file: StaticString = #filePath,
                         line: UInt = #line) -> (sut: PhotoImageDataLoaderAdapter, loader: RemoteImageDataLoaderSpy) {
        let loader = RemoteImageDataLoaderSpy()
        let sut = PhotoImageDataLoaderAdapter(imageDataLoader: loader)
        
        return (sut, loader)
    }
    
    private class RemoteImageDataLoaderSpy: ImageDataLoader {
        typealias Stub = Result<Data, Error>
        
        private(set) var loggedURLs = [URL]()
        
        func loadImageData(for url: URL) async throws -> Data {
            loggedURLs.append(url)
            throw anyNSError()
        }
    }
    
}
