//
//  CacheImageDataUseCaseTests.swift
//  PicsumAppTests
//
//  Created by Tsz-Lung on 11/07/2023.
//

import XCTest
@testable import PicsumApp

final class CacheImageDataUseCaseTests: XCTestCase {

    func test_init_noTriggerStore() {
        let (_, store) = makeSUT()
        
        XCTAssertEqual(store.messages.count, 0)
    }
    
    func test_save_deliversErrorWhenReceivedInsertError() async {
        let (sut, store) = makeSUT(insertStubs: [.failure(anyNSError())])
        let url = anyURL()
        
        await asyncAssertThrowsError(try await sut.save(data: anyData(), for: url)) { error in
            XCTAssertEqual(error as? LocalImageDataLoader.SaveError, .failed)
        }
        XCTAssertEqual(store.messages, [.insert(url)])
    }
    
    func test_save_insertDataAndTimestampForURLSuccessfully() async throws {
        let now = Date.distantFuture
        let (sut, store) = makeSUT(insertStubs: [.success(())], currentDate: { now })
        let data = Data("data for save".utf8)
        let url = URL(string: "https://save-image-url.com")!
        
        try await sut.save(data: data, for: url)
        
        XCTAssertEqual(store.insertedData, [.init(data: data, timestamp: now)])
        XCTAssertEqual(store.messages, [.insert(url)])
    }
    
    // MARK: - Helpers
    
    private func makeSUT(insertStubs: [ImageDataStoreSpy.InsertStub] = [],
                         currentDate: @escaping () -> Date = Date.init,
                         file: StaticString = #filePath,
                         line: UInt = #line) -> (sut: LocalImageDataLoader, store: ImageDataStoreSpy) {
        let store = ImageDataStoreSpy(retrieveDataStubs: [], insertStubs: insertStubs, deleteAllDataStubs: [])
        let sut = LocalImageDataLoader(store: store, currentDate: currentDate)
        
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        
        return (sut, store)
    }
    
}
