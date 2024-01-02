//
//  SwiftDataImageDataStoreTests.swift
//  PicsumAppTests
//
//  Created by Tsz-Lung on 02/01/2024.
//

import XCTest
import SwiftData
@testable import PicsumApp

final class SwiftDataImageDataStore: ImageDataStore {
    func retrieveData(for url: URL) async throws -> Data? {
        nil
    }
    
    func insert(data: Data, timestamp: Date, for url: URL) async throws {
        
    }
    
    func deleteAllData(until date: Date) async throws {
        
    }
}

final class SwiftDataImageDataStoreTests: XCTestCase {
    func test_retrievesData_deliversNilWhenNoCache() async throws {
        let sut = try makeSUT()
        
        let retrievedData = try await sut.retrieveData(for: anyURL())
        
        XCTAssertNil(retrievedData)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) throws -> ImageDataStore {
        let sut = SwiftDataImageDataStore()
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
}
