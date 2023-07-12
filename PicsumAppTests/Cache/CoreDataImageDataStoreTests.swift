//
//  CoreDataImageDataStoreTests.swift
//  PicsumAppTests
//
//  Created by Tsz-Lung on 12/07/2023.
//

import XCTest
@testable import PicsumApp

class CoreDataImageDataStore {
    init() {
        
    }
    
    func retrieveData(for url: URL) async throws -> Data? {
        return nil
    }
}

final class CoreDataImageDataStoreTests: XCTestCase {

    func test_retrieveData_deliversNilWhenNoCache() async throws {
        let sut = makeSUT()
        
        let data = try await sut.retrieveData(for: anyURL())
        
        XCTAssertNil(data)
    }

    func test_retrieveDataTwice_deliversNilWhenNoCacheWithNoSideEffects() async throws {
        let sut = makeSUT()
        
        let firstRetrievedData = try await sut.retrieveData(for: anyURL())
        let lastRetrievedData = try await sut.retrieveData(for: anyURL())
        
        XCTAssertNil(firstRetrievedData)
        XCTAssertNil(lastRetrievedData)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> CoreDataImageDataStore {
        let sut = CoreDataImageDataStore()
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
}
