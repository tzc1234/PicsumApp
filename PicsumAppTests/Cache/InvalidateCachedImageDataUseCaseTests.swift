//
//  InvalidateCachedImageDataUseCaseTests.swift
//  PicsumAppTests
//
//  Created by Tsz-Lung on 11/07/2023.
//

import XCTest
@testable import PicsumApp

final class InvalidateCachedImageDataUseCaseTests: XCTestCase {

    func test_init_noTriggerStore() {
        let (_, store) = makeSUT()
        
        XCTAssertEqual(store.messages.count, 0)
    }
    
    func test_invalidateImageData_deliversErrorOnStoreError() async {
        let (sut, store) = makeSUT(invalidateDataStubs: [.failure(anyNSError())])
        
        do {
            try await sut.invalidateImageData()
            XCTFail("Should not success")
        } catch {
            XCTAssertEqual(error as? LocalImageDataLoader.InvalidateError, .failed)
        }
        XCTAssertEqual(store.messages, [.invalidateAllData])
    }
    
    func test_invalidateImageData_succeedsOnStore() async throws {
        let now = Date()
        let (sut, store) = makeSUT(invalidateDataStubs: [.success(())], currentDate: { now })
        
        try await sut.invalidateImageData()
        
        let expirationDate = now.adding(days: -maxCacheDays)
        XCTAssertEqual(store.invalidatedDates, [expirationDate])
        XCTAssertEqual(store.messages, [.invalidateAllData])
    }

    // MARK: - Helpers
    
    private func makeSUT(invalidateDataStubs: [ImageDataStoreSpy.InvalidateDataStub] = [],
                         currentDate: @escaping () -> Date = Date.init,
                         file: StaticString = #filePath,
                         line: UInt = #line) -> (sut: LocalImageDataLoader, store: ImageDataStoreSpy) {
        let store = ImageDataStoreSpy(
            retrieveStubs: [],
            deleteDataStubs: [],
            insertStubs: [],
            invalidateDataStubs: invalidateDataStubs)
        let sut = LocalImageDataLoader(store: store, currentDate: currentDate)
        
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        
        return (sut, store)
    }
    
}
