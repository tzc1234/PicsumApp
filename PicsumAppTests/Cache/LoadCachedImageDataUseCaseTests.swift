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
        let url = URL(string: "https://load-image-url.com")!
        
        _ = try? await sut.loadImageData(for: url)
        
        XCTAssertEqual(store.messages, [.retrieve(url)])
    }
    
    func test_loadImageData_deliversFailedErrorOnStoreError() async {
        let (sut, store) = makeSUT(retrieveStubs: [.failure(anyNSError())])
        
        await expect(sut, store: store, withError: .failed)
    }
    
    func test_loadImageData_deliversNotFoundErrorWhenNoDataFound() async {
        let (sut, store) = makeSUT(retrieveStubs: [.success(nil)])
        
        await expect(sut, store: store, withError: .notFound)
    }
    
    func test_loadImageData_deliversNotFoundErrorWhenExpiredDataFound() async {
        let now = Date()
        let expireDate = expireDate(against: now)
        let (sut, store) = makeSUT(retrieveStubs: [.success((anyData(), expireDate))], currentDate: { now })
        
        await expect(sut, store: store, withError: .notFound)
    }
    
    func test_loadImageData_deliversNotFoundErrorWhenDataOnExpiration() async {
        let now = Date()
        let expirationData = expirationData(against: now)
        let (sut, store) = makeSUT(retrieveStubs: [.success((anyData(), expirationData))], currentDate: { now })
        
        await expect(sut, store: store, withError: .notFound)
    }
    
    func test_loadImageData_deliversDataWhenNonExpiredDataFound() async throws {
        let now = Date()
        let nonExpiredDate = nonExpireDate(against: now)
        let data = anyData()
        let (sut, store) = makeSUT(retrieveStubs: [.success((data, nonExpiredDate))], currentDate: { now })
        
        let receivedData = try await sut.loadImageData(for: anyURL())
        
        XCTAssertEqual(receivedData, data)
        XCTAssertEqual(store.messages, [.retrieve(anyURL())])
    }
    
    // MARK: - Helpers
    
    private func makeSUT(retrieveStubs: [ImageDataStoreSpy.RetrieveStub] = [],
                         currentDate: @escaping () -> Date = Date.init,
                         file: StaticString = #filePath,
                         line: UInt = #line) -> (sut: LocalImageDataLoader, store: ImageDataStoreSpy) {
        let store = ImageDataStoreSpy(retrieveStubs: retrieveStubs)
        let sut = LocalImageDataLoader(store: store, currentDate: currentDate)
        
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        
        return (sut, store)
    }
    
    private func expect(_ sut: LocalImageDataLoader, store: ImageDataStoreSpy,
                        withError expectedError: LocalImageDataLoader.LoadError,
                        file: StaticString = #filePath, line: UInt = #line) async {
        do {
            _ = try await sut.loadImageData(for: anyURL())
            XCTFail("Should not success", file: file, line: line)
        } catch {
            XCTAssertEqual(error as? LocalImageDataLoader.LoadError, expectedError, file: file, line: line)
        }
        XCTAssertEqual(store.messages, [.retrieve(anyURL())], file: file, line: line)
    }
    
    private func nonExpireDate(against date: Date) -> Date {
        date.adding(days: -maxCacheDays).adding(seconds: 1)
    }
    
    private func expireDate(against date: Date) -> Date {
        date.adding(days: -maxCacheDays).adding(seconds: -1)
    }
    
    private func expirationData(against date: Date) -> Date {
        date.adding(days: -maxCacheDays)
    }
    
    private var maxCacheDays: Int { 7 }
    
    class ImageDataStoreSpy: ImageDataStore {
        typealias RetrieveStub = Result<(Data, Date)?, Error>
        
        enum Message: Equatable {
            case retrieve(URL)
        }
        
        private(set) var messages = [Message]()
        
        private var retrieveStubs: [RetrieveStub]
        
        init(retrieveStubs: [RetrieveStub]) {
            self.retrieveStubs = retrieveStubs
        }
        
        func retrieve(for url: URL) async throws -> (data: Data, timestamp: Date)? {
            messages.append(.retrieve(url))
            return try retrieveStubs.removeFirst().get()
        }
    }
    
}
