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
    
    func test_loadImageData_deliversFailedErrorOnStoreError() async {
        let (sut, store) = makeSUT(retrieveStubs: [.failure(anyNSError())])
        
        await expect(sut, store: store, withError: .failed)
    }
    
    func test_loadImageData_deliversErrorWhenNoDataFound() async {
        let (sut, store) = makeSUT(retrieveStubs: [.success(nil)])
        
        await expect(sut, store: store, withError: .notFound)
    }
    
    func test_loadImageData_deliversDataWhenDataFound() async throws {
        let data = anyData()
        let (sut, store) = makeSUT(retrieveStubs: [.success(data)])
        let url = URL(string: "https://load-image-url.com")!
        
        let receivedData = try await sut.loadImageData(for: url)
        
        XCTAssertEqual(receivedData, data)
        XCTAssertEqual(store.messages, [.retrieve(url)])
    }
    
    // MARK: - Helpers
    
    private func makeSUT(retrieveStubs: [ImageDataStoreSpy.RetrieveStub] = [],
                         currentDate: @escaping () -> Date = Date.init,
                         file: StaticString = #filePath,
                         line: UInt = #line) -> (sut: LocalImageDataLoader, store: ImageDataStoreSpy) {
        let store = ImageDataStoreSpy(
            retrieveStubs: retrieveStubs,
            deleteDataStubs: [],
            insertStubs: [],
            deleteAllDataStubs: [])
        let sut = LocalImageDataLoader(store: store, currentDate: currentDate)
        
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        
        return (sut, store)
    }
    
    private func expect(_ sut: LocalImageDataLoader, store: ImageDataStoreSpy,
                        withError expectedError: LocalImageDataLoader.LoadError,
                        file: StaticString = #filePath, line: UInt = #line) async {
        let url = anyURL()
        
        do {
            _ = try await sut.loadImageData(for: url)
            XCTFail("Should not success", file: file, line: line)
        } catch {
            XCTAssertEqual(error as? LocalImageDataLoader.LoadError, expectedError, file: file, line: line)
        }
        XCTAssertEqual(store.messages, [.retrieve(url)], file: file, line: line)
    }
    
}
