//
//  SwiftDataImageDataStoreTests.swift
//  PicsumAppTests
//
//  Created by Tsz-Lung on 02/01/2024.
//

import XCTest
@testable import PicsumApp

final class SwiftDataImageDataStoreTests: XCTestCase {
    func test_retrievesData_deliversNilWhenNoCache() async throws {
        let sut = try makeSUT()
        
        let retrievedData = try await sut.retrieveData(for: anyURL())
        
        XCTAssertNil(retrievedData)
    }
    
    func test_retrievesDataTwice_deliversNilWhenNoCacheWithNoSideEffects() async throws {
        let sut = try makeSUT()
        let url = anyURL()
        
        let firstRetrievedData = try await sut.retrieveData(for: url)
        let lastRetrievedData = try await sut.retrieveData(for: url)
        
        XCTAssertNil(firstRetrievedData)
        XCTAssertNil(lastRetrievedData)
    }
    
    func test_retrievesData_deliversCachedData() async throws {
        let sut = try makeSUT()
        let url = anyURL()
        let data = anyData()
        
        try await insert(data: data, url: url, to: sut)
        let retrievedData = try await sut.retrieveData(for: url)
        
        XCTAssertEqual(retrievedData, data)
    }
    
    func test_retrievesDataTwice_deliversSameCachedData() async throws {
        let sut = try makeSUT()
        let url = anyURL()
        let data = anyData()
        
        try await insert(data: data, url: url, to: sut)
        let firstRetrievedData = try await sut.retrieveData(for: url)
        let lastRetrievedData = try await sut.retrieveData(for: url)
        
        XCTAssertEqual(firstRetrievedData, data)
        XCTAssertEqual(lastRetrievedData, data)
    }
    
    func test_insert_overridesOldDataWithNewData() async throws {
        let sut = try makeSUT()
        let overrideDataURL = URL(string: "https://override-data-url.com")!
        let oldDataInput = DataInput(data: Data("old data".utf8), url: overrideDataURL)
        let newDataInput = DataInput(data: Data("new data".utf8), url: overrideDataURL)
        let otherDataInput = DataInput(data: Data("other data".utf8), url: URL(string: "https://other-data-url.com")!)
        
        try await insert(inputs: [otherDataInput, oldDataInput, newDataInput], into: sut)
        let retrievedData = try await sut.retrieveData(for: overrideDataURL)
        let retrievedOtherData = try await sut.retrieveData(for: otherDataInput.url)
        
        XCTAssertEqual(retrievedData, newDataInput.data)
        XCTAssertEqual(retrievedOtherData, otherDataInput.data)
    }
    
    func test_deleteAll_ignoresWhenNoCache() async throws {
        let sut = try makeSUT()
        let url = anyURL()
        
        let beforeDeleteAllData = try await sut.retrieveData(for: url)
        try await sut.deleteAllData(until: .now)
        let afterDeleteAllData = try await sut.retrieveData(for: url)
        
        XCTAssertNil(beforeDeleteAllData)
        XCTAssertNil(afterDeleteAllData)
    }
    
    func test_deleteAll_removesExpiredAndOnExpirationData() async throws {
        let sut = try makeSUT()
        let date = Date()
        let expiredInput = DataInput(
            data: Data("expired data".utf8),
            date: date.adding(seconds: -1),
            url: URL(string: "https://expired-data-url.com")!)
        let onExpirationInput = DataInput(
            data: Data("on expiration data".utf8),
            date: date,
            url: URL(string: "https://on-expiration-data-url.com")!)
        let nonExpiredInput = DataInput(
            data: Data("non expired data".utf8),
            date: date.adding(seconds: 1),
            url: URL(string: "https://non-expired-data-url.com")!)
        
        try await insert(inputs: [expiredInput, onExpirationInput, nonExpiredInput], into: sut)
        try await deleteAllData(in: sut, until: date)
        let expiredData = try await sut.retrieveData(for: expiredInput.url)
        let onExpirationData = try await sut.retrieveData(for: onExpirationInput.url)
        let nonExpiredData = try await sut.retrieveData(for: nonExpiredInput.url)
        
        XCTAssertNil(expiredData)
        XCTAssertNil(onExpirationData)
        XCTAssertEqual(nonExpiredData, nonExpiredInput.data)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) throws -> ImageDataStore {
        let sut = try SwiftDataImageDataStore(isStoredInMemoryOnly: true)
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    private func deleteAllData(in sut: ImageDataStore, until date: Date,
                               file: StaticString = #filePath, line: UInt = #line) async throws {
        let notificationSpy = ContextDidSaveNotificationSpy()
        
        try await sut.deleteAllData(until: date)
        
        XCTAssertTrue(notificationSpy.saveCount > 0, "Expect at least save once", file: file, line: line)
    }
    
    private func insert(inputs: [DataInput], into sut: ImageDataStore,
                        file: StaticString = #filePath, line: UInt = #line) async throws {
        for input in inputs {
            try await insert(data: input.data, timestamp: input.date, url: input.url, to: sut, file: file, line: line)
        }
    }
    
    private func insert(data: Data, timestamp: Date = Date(), url: URL, to sut: ImageDataStore,
                        file: StaticString = #filePath, line: UInt = #line) async throws {
        let notificationSpy = ContextDidSaveNotificationSpy()
        
        try await sut.insert(data: data, timestamp: timestamp, for: url)
        
        XCTAssertTrue(notificationSpy.saveCount > 0, "Expect at least save once", file: file, line: line)
    }
    
    private struct DataInput {
        let data: Data
        let date: Date
        let url: URL
        
        init(data: Data, date: Date = Date(), url: URL) {
            self.data = data
            self.date = date
            self.url = url
        }
    }
}
