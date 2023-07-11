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
    
    func test_save_deliversErrorWhenReceivedDeleteError() async {
        let (sut, store) = makeSUT(deleteDataStubs: [.failure(anyNSError())])
        let url = anyURL()
        
        do {
            try await sut.save(data: anyData(), for: url)
            XCTFail("Should not success")
        } catch {
            XCTAssertEqual(error as? LocalImageDataLoader.SaveError, .existedDataRemovalFailed)
        }
        XCTAssertEqual(store.messages, [.deleteData(url)])
    }
    
    func test_save_deliversErrorWhenReceivedInsertError() async {
        let (sut, store) = makeSUT(deleteDataStubs: [.success(())], insertStubs: [.failure(anyNSError())])
        let url = anyURL()
        
        do {
            try await sut.save(data: anyData(), for: url)
            XCTFail("Should not success")
        } catch {
            XCTAssertEqual(error as? LocalImageDataLoader.SaveError, .failed)
        }
        XCTAssertEqual(store.messages, [.deleteData(url), .insert(url)])
    }
    
    // MARK: - Helpers
    
    private func makeSUT(deleteDataStubs: [ImageDataStoreSpy.DeleteDataStub] = [],
                         insertStubs: [ImageDataStoreSpy.InsertStub] = [],
                         currentDate: @escaping () -> Date = Date.init,
                         file: StaticString = #filePath,
                         line: UInt = #line) -> (sut: LocalImageDataLoader, store: ImageDataStoreSpy) {
        let store = ImageDataStoreSpy(retrieveStubs: [], deleteDataStubs: deleteDataStubs, insertStubs: insertStubs)
        let sut = LocalImageDataLoader(store: store, currentDate: currentDate)
        
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        
        return (sut, store)
    }
    
}
