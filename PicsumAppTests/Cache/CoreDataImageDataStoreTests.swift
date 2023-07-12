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
        let sut = CoreDataImageDataStore()
        
        let data = try await sut.retrieveData(for: anyURL())
        
        XCTAssertNil(data)
    }

}
