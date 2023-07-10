//
//  LoadCachedImageDataUseCaseTests.swift
//  PicsumAppTests
//
//  Created by Tsz-Lung on 10/07/2023.
//

import XCTest
@testable import PicsumApp

final class LoadCachedImageDataUseCaseTests: XCTestCase {

    class LocalImageDataLoader: ImageDataLoader {
        private let store: ImageDataStoreSpy
        
        init(store: ImageDataStoreSpy) {
            self.store = store
        }
        
        enum LoadError: Error {
            case failed
        }
        
        func loadImageData(for url: URL) async throws -> Data {
            do {
                try store.retrieve(for: url)
            } catch {
                throw LoadError.failed
            }
            
            return Data()
        }
    }
    
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
    
    class ImageDataStoreSpy {
        typealias RetrieveStub = Result<Data, Error>
        
        enum Message: Equatable {
            case retrieve(URL)
        }
        
        private(set) var messages = [Message]()
        
        private var retrieveStubs: [RetrieveStub]
        
        init(retrieveStubs: [RetrieveStub]) {
            self.retrieveStubs = retrieveStubs
        }
        
        func retrieve(for url: URL) throws {
            messages.append(.retrieve(url))
            try _ = retrieveStubs.removeFirst().get()
        }
    }
    
}
