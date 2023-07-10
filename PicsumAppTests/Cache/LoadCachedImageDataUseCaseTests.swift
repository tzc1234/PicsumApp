//
//  LoadCachedImageDataUseCaseTests.swift
//  PicsumAppTests
//
//  Created by Tsz-Lung on 10/07/2023.
//

import XCTest
@testable import PicsumApp

final class LoadCachedImageDataUseCaseTests: XCTestCase {

    func test_init_noTriggerStore() {
        let (_, store) = makeSUT()
        
        XCTAssertEqual(store.messages.count, 0)
    }
    
    func test_loadImageData_requestsCachedDateForCorrectURL() async {
        let (sut, store) = makeSUT(retrieveStubs: [.failure(anyNSError())])
        let url = URL(string: "https://laod-image-url.com")!
        
        _ = try? await sut.loadImageData(for: url)
        
        XCTAssertEqual(store.messages, [.retrieve(url)])
    }
    
    func test_loadImageData_deliversFailedErrorOnStoreError() async {
        let (sut, _) = makeSUT(retrieveStubs: [.failure(anyNSError())])
        
        do {
            _ = try await sut.loadImageData(for: anyURL())
            XCTFail("Should not success")
        } catch {
            XCTAssertEqual(error as? LocalImageDataLoader.LoadError, .failed)
        }
    }
    
    func test_loadImageData_deliversNotFoundErrorWhenNoDataFound() async {
        let (sut, _) = makeSUT(retrieveStubs: [.success(nil)])
        
        do {
            _ = try await sut.loadImageData(for: anyURL())
            XCTFail("Should not success")
        } catch {
            XCTAssertEqual(error as? LocalImageDataLoader.LoadError, .notFound)
        }
    }
    
    func test_loadImageData_deliversDataWhenDataFound() async throws {
        let data = anyData()
        let (sut, _) = makeSUT(retrieveStubs: [.success(data)])
        
        let receivedData = try await sut.loadImageData(for: anyURL())
        
        XCTAssertEqual(receivedData, data)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(retrieveStubs: [ImageDataStoreSpy.RetrieveStub] = [],
                         file: StaticString = #filePath,
                         line: UInt = #line) -> (sut: LocalImageDataLoader, store: ImageDataStoreSpy) {
        let store = ImageDataStoreSpy(retrieveStubs: retrieveStubs)
        let sut = LocalImageDataLoader(store: store)
        
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        
        return (sut, store)
    }
    
    class ImageDataStoreSpy: ImageDataStore {
        typealias RetrieveStub = Result<Data?, Error>
        
        enum Message: Equatable {
            case retrieve(URL)
        }
        
        private(set) var messages = [Message]()
        
        private var retrieveStubs: [RetrieveStub]
        
        init(retrieveStubs: [RetrieveStub]) {
            self.retrieveStubs = retrieveStubs
        }
        
        func retrieve(for url: URL) async throws -> Data? {
            messages.append(.retrieve(url))
            return try retrieveStubs.removeFirst().get()
        }
    }
    
}
