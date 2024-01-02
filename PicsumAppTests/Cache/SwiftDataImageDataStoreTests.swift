//
//  SwiftDataImageDataStoreTests.swift
//  PicsumAppTests
//
//  Created by Tsz-Lung on 02/01/2024.
//

import XCTest
import SwiftData
@testable import PicsumApp

@Model
final class SwiftDataImage {
    var data: Data
    var timestamp: Date
    var url: URL
    
    init(data: Data, timestamp: Date, url: URL) {
        self.data = data
        self.timestamp = timestamp
        self.url = url
    }
}

final actor SwiftDataImageDataStore: ModelActor, ImageDataStore {
    let modelContainer: ModelContainer
    let modelExecutor: ModelExecutor
    private let modelContext: ModelContext
    
    init(configuration: ModelConfiguration) throws {
        self.modelContainer = try ModelContainer(for: SwiftDataImage.self, configurations: configuration)
        self.modelContext = ModelContext(modelContainer)
        self.modelExecutor = DefaultSerialModelExecutor(modelContext: modelContext)
    }
    
    func retrieveData(for url: URL) throws -> Data? {
        var descriptor = FetchDescriptor<SwiftDataImage>()
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first?.data
    }
    
    func insert(data: Data, timestamp: Date, for url: URL) throws {
        modelContext.insert(SwiftDataImage(data: data, timestamp: timestamp, url: url))
        try modelContext.save()
    }
    
    func deleteAllData(until date: Date) throws {
        
    }
}

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
    
    // MARK: - Helpers
    
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) throws -> ImageDataStore {
        let sut = try SwiftDataImageDataStore(configuration: .init(isStoredInMemoryOnly: true))
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
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
