//
//  ImageDataLoaderCacheDecoratorTests.swift
//  PicsumAppTests
//
//  Created by Tsz-Lung on 13/07/2023.
//

import XCTest
@testable import PicsumApp

class ImageDataLoaderCacheDecorator: ImageDataLoader {
    private let loader: ImageDataLoader
    
    init(loader: ImageDataLoader) {
        self.loader = loader
    }
    
    func loadImageData(for url: URL) async throws -> Data {
        _ = try await loader.loadImageData(for: url)
        return Data()
    }
}

final class ImageDataLoaderCacheDecoratorTests: XCTestCase {

    func test_init_noTriggerOnLoader() {
        let (_, loader) = makeSUT()
        
        XCTAssertEqual(loader.loggedURLs.count, 0)
    }
    
    func test_loadImageData_loadFromLoader() async throws {
        let (sut, loader) = makeSUT(stubs: [.success(anyData())])
        let url = anyURL()
        
        _ = try await sut.loadImageData(for: url)
        
        XCTAssertEqual(loader.loggedURLs, [url])
    }
    
    func test_loadImageData_deliversErrorOnLoaderError() async {
        let (sut, _) = makeSUT(stubs: [.failure(anyNSError())])
        
        do {
            _ = try await sut.loadImageData(for: anyURL())
            XCTFail("Should not success")
        } catch {}
    }

    // MARK: - Helpers
    
    private func makeSUT(stubs: [RemoteImageDataLoaderSpy.Stub] = [],
                         file: StaticString = #filePath,
                         line: UInt = #line) -> (sut: ImageDataLoaderCacheDecorator, loader: RemoteImageDataLoaderSpy) {
        let loader = RemoteImageDataLoaderSpy(stubs: stubs)
        let sut = ImageDataLoaderCacheDecorator(loader: loader)
        trackForMemoryLeaks(loader, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, loader)
    }
    
}
