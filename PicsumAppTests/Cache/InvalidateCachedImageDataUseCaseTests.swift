//
//  InvalidateCachedImageDataUseCaseTests.swift
//  PicsumAppTests
//
//  Created by Tsz-Lung on 11/07/2023.
//

import XCTest
@testable import PicsumApp

final class InvalidateCachedImageDataUseCaseTests: XCTestCase {

    func test_init_doesNotTriggerStore() {
        let (_, store) = makeSUT()
        
        XCTAssertEqual(store.messages.count, 0)
    }
    
    func test_invalidatesImageData_deliversErrorOnStoreError() async {
        let (sut, store) = makeSUT(deleteAllDataStubs: [.failure(anyNSError())])
        
        await asyncAssertThrowsError(try await sut.invalidateImageData()) { error in
            XCTAssertEqual(error as? LocalImageDataLoader.InvalidateError, .failed)
        }
        XCTAssertEqual(store.messages, [.deleteAllData])
    }
    
    func test_invalidatesImageData_succeedsOnStore() async throws {
        let now = Date()
        let (sut, store) = makeSUT(deleteAllDataStubs: [.success(())], currentDate: { now })
        
        try await sut.invalidateImageData()
        
        let expirationDate = now.adding(days: -maxCacheDays)
        XCTAssertEqual(store.datesForDeleteAllData, [expirationDate])
        XCTAssertEqual(store.messages, [.deleteAllData])
    }

    // MARK: - Helpers
    
    private func makeSUT(deleteAllDataStubs: [ImageDataStoreSpy.DeleteAllDataStub] = [],
                         currentDate: @escaping () -> Date = Date.init,
                         file: StaticString = #filePath,
                         line: UInt = #line) -> (sut: LocalImageDataLoader, store: ImageDataStoreSpy) {
        let store = ImageDataStoreSpy(retrieveDataStubs: [], insertStubs: [], deleteAllDataStubs: deleteAllDataStubs)
        let sut = LocalImageDataLoader(store: store, currentDate: currentDate)
        
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        
        return (sut, store)
    }
    
}
