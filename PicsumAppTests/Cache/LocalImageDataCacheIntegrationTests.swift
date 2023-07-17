//
//  LocalImageDataCacheIntegrationTests.swift
//  PicsumAppTests
//
//  Created by Tsz-Lung on 17/07/2023.
//

import XCTest
@testable import PicsumApp

final class LocalImageDataCacheIntegrationTests: XCTestCase {

    override func setUp() {
        super.setUp()
        deleteStoreArtifacts()
    }
    
    override func tearDown() {
        super.tearDown()
        deleteStoreArtifacts()
    }
    
    func test_loadImageData_deliversSavedDataOnASeparateInstance() async throws {
        let imageLoaderForSave = try makeSUT()
        let imageLoaderForLoad = try makeSUT()
        let data = anyData()
        let url = anyURL()
        
        try await imageLoaderForSave.save(data: data, for: url)
        let receivedData = try await imageLoaderForLoad.loadImageData(for: url)
        
        XCTAssertEqual(receivedData, data)
    }
    
    func test_save_overridesSavedDataOnASeparateInstance() async throws {
        let imageLoaderForFirstSave = try makeSUT()
        let imageLoaderForLastSave = try makeSUT()
        let imageLoaderForLoad = try makeSUT()
        let firstData = Data("first data".utf8)
        let lastData = Data("last data".utf8)
        let url = anyURL()
        
        try await imageLoaderForFirstSave.save(data: firstData, for: url)
        try await imageLoaderForLastSave.save(data: lastData, for: url)
        let receivedData = try await imageLoaderForLoad.loadImageData(for: url)
        
        XCTAssertEqual(receivedData, lastData)
    }

    // MARK: - Helpers
    
    private func makeSUT(currentDate: Date = .init(),
                         file: StaticString = #filePath,
                         line: UInt = #line) throws -> LocalImageDataLoader {
        let store = try CoreDataImageDataStore(storeURL: storeURLForTest())
        let sut = LocalImageDataLoader(store: store)
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    private func deleteStoreArtifacts() {
        try? FileManager.default.removeItem(at: storeURLForTest())
    }
    
    private func storeURLForTest() -> URL {
        let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        return cachesDirectory.appending(path: "\(type(of: self)).store")
    }
    
}
