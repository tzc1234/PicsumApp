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
    
    func test_loadImageData_deliversNotFoundErrorWhenExpiredDataFound() async throws {
        let now = Date()
        let expireDate = expireDate(against: now)
        let (sut, _) = makeSUT(retrieveStubs: [.success((anyData(), expireDate))], currentDate: { now })
        
        do {
            _ = try await sut.loadImageData(for: anyURL())
            XCTFail("Should not success")
        } catch {
            XCTAssertEqual(error as? LocalImageDataLoader.LoadError, .notFound)
        }
    }
    
    func test_loadImageData_deliversDataWhenNonExpiredDataFound() async throws {
        let now = Date()
        let nonExpiredDate = nonExpireDate(against: now)
        let data = anyData()
        let (sut, _) = makeSUT(retrieveStubs: [.success((data, nonExpiredDate))], currentDate: { now })
        
        let receivedData = try await sut.loadImageData(for: anyURL())
        
        XCTAssertEqual(receivedData, data)
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
    
    private func nonExpireDate(against date: Date) -> Date {
        date.adding(days: -maxCacheDays).adding(seconds: 1)
    }
    
    private func expireDate(against date: Date) -> Date {
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

extension Date {
    func adding(days: Int) -> Date {
        Calendar(identifier: .gregorian).date(byAdding: .day, value: days, to: self)!
    }

    func adding(seconds: TimeInterval) -> Date {
        self + seconds
    }
}
