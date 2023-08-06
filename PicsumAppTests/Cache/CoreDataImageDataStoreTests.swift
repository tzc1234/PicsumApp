//
//  CoreDataImageDataStoreTests.swift
//  PicsumAppTests
//
//  Created by Tsz-Lung on 12/07/2023.
//

import XCTest
@testable import PicsumApp

final class CoreDataImageDataStoreTests: XCTestCase {

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
    
    func test_retrievesData_deliversDataWhenCached() async throws {
        let sut = try makeSUT()
        let url = anyURL()
        let data = anyData()
        
        try await insert(data: data, url: url, to: sut)
        let retrievedData = try await sut.retrieveData(for: url)
        
        XCTAssertEqual(retrievedData, data)
    }
    
    func test_retrievesDataTwice_deliversSameDataWhenCached() async throws {
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
    
    func test_deleteAll_removesDataLessThanOrEqualToTheDate() async throws {
        let sut = try makeSUT()
        let date = Date()
        let lessThanDateInput = DataInput(
            data: Data("less than date data".utf8),
            date: date.adding(seconds: -1),
            url: URL(string: "https://less-than-date-data-url.com")!)
        let equalToDateInput = DataInput(
            data: Data("equal to date data".utf8),
            date: date,
            url: URL(string: "https://equal-to-date-data-url.com")!)
        let moreThanDateInput = DataInput(
            data: Data("more than date data".utf8),
            date: date.adding(seconds: 1),
            url: URL(string: "https://more-than-date-data-url.com")!)
        
        try await insert(inputs: [lessThanDateInput, equalToDateInput, moreThanDateInput], into: sut)
        try await sut.deleteAllData(until: date)
        let lessThanDateData = try await sut.retrieveData(for: lessThanDateInput.url)
        let equalToDateData = try await sut.retrieveData(for: equalToDateInput.url)
        let moreThanDateData = try await sut.retrieveData(for: moreThanDateInput.url)
        
        XCTAssertNil(lessThanDateData)
        XCTAssertNil(equalToDateData)
        XCTAssertEqual(moreThanDateData, moreThanDateInput.data)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) throws -> ImageDataStore {
        let sut = try CoreDataImageDataStore(storeURL: URL(filePath: "/dev/null"))
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
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
