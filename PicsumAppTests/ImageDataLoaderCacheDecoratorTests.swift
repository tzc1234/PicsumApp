//
//  ImageDataLoaderCacheDecoratorTests.swift
//  PicsumAppTests
//
//  Created by Tsz-Lung on 13/07/2023.
//

import XCTest
@testable import PicsumApp

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
    
    func test_loadImageData_deliversDataOnLoaderSuccess() async throws {
        let data = anyData()
        let (sut, _) = makeSUT(stubs: [.success(data)])
        
        let receivedData = try await sut.loadImageData(for: anyURL())
        
        XCTAssertEqual(receivedData, data)
    }
    
    func test_loadImageData_cachesDataOnLoaderSuccess() async throws {
        let data = anyData()
        let cache = CacheSpy()
        let (sut, _) = makeSUT(stubs: [.success(data)], cache: cache)
        let url = anyURL()
        
        _ = try await sut.loadImageData(for: url)
        
        XCTAssertEqual(cache.cachedData, [.init(data: data, url: url)])
    }
    
    func test_loadImageData_doesNotCacheDataOnLoaderError() async throws {
        let cache = CacheSpy()
        let (sut, _) = makeSUT(stubs: [.failure(anyNSError())], cache: cache)
        
        _ = try? await sut.loadImageData(for: anyURL())
            
        XCTAssertEqual(cache.cachedData.count, 0)
    }
    
    func test_loadImageData_ignoresCacheErrorWhenFailsOnCache() async {
        let cache = CacheSpy()
        let (sut, _) = makeSUT(stubs: [.success(anyData())], cache: cache)
        
        do {
            _ = try await sut.loadImageData(for: anyURL())
        } catch {
            XCTFail("Should not fail")
        }
    }

    // MARK: - Helpers
    
    private func makeSUT(stubs: [ImageDataLoaderSpy.Stub] = [],
                         cache: CacheSpy = .init(),
                         file: StaticString = #filePath,
                         line: UInt = #line) -> (sut: ImageDataLoaderCacheDecorator, loader: ImageDataLoaderSpy) {
        let loader = ImageDataLoaderSpy(stubs: stubs)
        let sut = ImageDataLoaderCacheDecorator(loader: loader, cache: cache)
        trackForMemoryLeaks(loader, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, loader)
    }
    
    private class CacheSpy: ImageDataCache {
        private(set) var cachedData = [Cached]()
        
        func save(data: Data, for url: URL) async throws {
            cachedData.append(.init(data: data, url: url))
            throw anyNSError()
        }
        
        struct Cached: Equatable {
            let data: Data
            let url: URL
        }
    }
    
}
