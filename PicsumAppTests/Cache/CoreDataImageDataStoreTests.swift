//
//  CoreDataImageDataStoreTests.swift
//  PicsumAppTests
//
//  Created by Tsz-Lung on 12/07/2023.
//

import XCTest
@testable import PicsumApp

final class CoreDataImageDataStoreTests: XCTestCase {

    func test_retrieveData_deliversNilWhenNoCache() async throws {
        let sut = try makeSUT()
        
        let retrievedData = try await sut.retrieveData(for: anyURL())
        
        XCTAssertNil(retrievedData)
    }

    func test_retrieveDataTwice_deliversNilWhenNoCacheWithNoSideEffects() async throws {
        let sut = try makeSUT()
        let url = anyURL()
        
        let firstRetrievedData = try await sut.retrieveData(for: url)
        let lastRetrievedData = try await sut.retrieveData(for: url)
        
        XCTAssertNil(firstRetrievedData)
        XCTAssertNil(lastRetrievedData)
    }
    
    func test_retrieveData_deliversDataWhenCached() async throws {
        let sut = try makeSUT()
        let url = anyURL()
        let data = anyData()
        
        try await insert(data: data, url: url, to: sut)
        let retrievedData = try await sut.retrieveData(for: url)
        
        XCTAssertEqual(retrievedData, data)
    }
    
    func test_retrieveDataTwice_deliversSameDataWhenCached() async throws {
        let sut = try makeSUT()
        let url = anyURL()
        let data = anyData()
        
        try await insert(data: data, url: url, to: sut)
        let firstRetrievedData = try await sut.retrieveData(for: url)
        let lastRetrievedData = try await sut.retrieveData(for: url)
        
        XCTAssertEqual(firstRetrievedData, data)
        XCTAssertEqual(lastRetrievedData, data)
    }
    
    func test_insert_overridesOldDataByNewData() async throws {
        let sut = try makeSUT()
        let url = anyURL()
        let oldData = Data("old data".utf8)
        let newData = Data("new data".utf8)
        
        try await insert(data: oldData, url: url, to: sut)
        let retrievedOldData = try await sut.retrieveData(for: url)
        
        try await insert(data: newData, url: url, to: sut)
        let retrievedNewData = try await sut.retrieveData(for: url)
        
        XCTAssertEqual(retrievedOldData, oldData)
        XCTAssertEqual(retrievedNewData, newData)
    }
    
    func test_deleteData_ignoresWhenNoCache() async throws {
        let sut = try makeSUT()
        let url = anyURL()
        
        let beforeDeleteData = try await sut.retrieveData(for: url)
        try await delete(for: url, to: sut, withExpectedSaveCount: 0)
        let afterDeleteData = try await sut.retrieveData(for: url)
        
        XCTAssertNil(beforeDeleteData)
        XCTAssertNil(afterDeleteData)
    }
    
    func test_deleteData_removeCachedData() async throws {
        let sut = try makeSUT()
        let url = anyURL()
        
        try await insert(data: anyData(), url: url, to: sut)
        try await delete(for: url, to: sut, withExpectedSaveCount: 1)
        let afterDeleteData = try await sut.retrieveData(for: url)
        
        XCTAssertNil(afterDeleteData)
    }
    
    func test_deleteAll_ignoresWhenNoCache() async throws {
        let sut = try makeSUT()
        let url = anyURL()
        
        let beforeDeleteAllData = try await sut.retrieveData(for: url)
        try await sut.deleteAllData(reach: anyDate())
        let afterDeleteAllData = try await sut.retrieveData(for: url)
        
        XCTAssertNil(beforeDeleteAllData)
        XCTAssertNil(afterDeleteAllData)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) throws -> CoreDataImageDataStore {
        let sut = try CoreDataImageDataStore(storeURL: URL(filePath: "/dev/null"))
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    private func delete(for url: URL, to sut: CoreDataImageDataStore, withExpectedSaveCount saveCount: Int,
                        file: StaticString = #filePath, line: UInt = #line) async throws {
        let notificationSpy = ContextDidSaveNotificationSpy()
        
        try await  sut.deleteData(for: url)
        
        XCTAssertEqual(notificationSpy.saveCount, saveCount, "Expect save \(saveCount) time(s), got \(notificationSpy.saveCount) instead", file: file, line: line)
    }
    
    private func insert(data: Data, timestamp: Date = Date(), url: URL, to sut: CoreDataImageDataStore,
                        file: StaticString = #filePath, line: UInt = #line) async throws {
        let notificationSpy = ContextDidSaveNotificationSpy()
        
        try await sut.insert(data: data, timestamp: timestamp, for: url)
        
        XCTAssertTrue(notificationSpy.saveCount > 0, "Expect at least save once", file: file, line: line)
    }
    
    private func anyDate() -> Date {
        Date()
    }
    
    private class ContextDidSaveNotificationSpy {
        private(set) var saveCount = 0
        
        init() {
            NotificationCenter.default.addObserver(self, selector: #selector(contextDisSave),
                                                   name: .NSManagedObjectContextDidSave,
                                                   object: nil)
        }
        
        @objc private func contextDisSave() {
            saveCount += 1
        }
        
        deinit {
            NotificationCenter.default.removeObserver(self)
        }
    }
    
}
