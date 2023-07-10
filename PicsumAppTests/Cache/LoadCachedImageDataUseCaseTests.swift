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
        
        func loadImageData(for url: URL) async throws -> Data {
            store.retrieve(for: url)
            throw anyNSError()
        }
    }
    
    func test_init_noTriggerStore() {
        let (_, store) = makeSUT()
        
        XCTAssertEqual(store.messages.count, 0)
    }
    
    func test_loadImageData_requestsCachedDateForCorrectURL() async {
        let (sut, store) = makeSUT()
        let url = URL(string: "https://laod-image-url.com")!
        
        _ = try? await sut.loadImageData(for: url)
        
        XCTAssertEqual(store.messages, [.retrieve(url)])
    }
    
    // MARK: - Helpers
    
    private func makeSUT(file: StaticString = #filePath,
                         line: UInt = #line) -> (sut: LocalImageDataLoader, store: ImageDataStoreSpy) {
        let store = ImageDataStoreSpy()
        let sut = LocalImageDataLoader(store: store)
        
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        
        return (sut, store)
    }
    
    class ImageDataStoreSpy {
        private(set) var messages = [Message]()
        
        enum Message: Equatable {
            case retrieve(URL)
        }
        
        func retrieve(for url: URL) {
            messages.append(.retrieve(url))
        }
        
    }
    
}
