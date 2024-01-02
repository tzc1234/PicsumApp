//
//  LocalImageDataCacheIntegrationTests.swift
//  PicsumAppTests
//
//  Created by Tsz-Lung on 17/07/2023.
//

import XCTest
@testable import PicsumApp

final class LocalImageDataCacheIntegrationTests: XCTestCase {

    override func setUp() async throws {
        try await super.setUp()
        await deleteStoreArtifacts()
    }
    
    override func tearDown() async throws {
        try await super.tearDown()
        await deleteStoreArtifacts()
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
    
    func test_invalidateImageData_removesAllSavedDataInADistancePast() async throws {
        let imageLoaderForSave = try makeSUT(currentDate: { .distantPast })
        let imageLoaderForInvalidate = try makeSUT(currentDate: { .now })
        let imageLoaderForLoad = try makeSUT()
        let data = anyData()
        let url = anyURL()
        
        try await imageLoaderForSave.save(data: data, for: url)
        try await imageLoaderForInvalidate.invalidateImageData()
        
        await asyncAssertThrowsError(_ = try await imageLoaderForLoad.loadImageData(for: url))
    }

    // MARK: - Helpers
    
    private func makeSUT(currentDate: @escaping () -> Date = Date.init,
                         file: StaticString = #filePath,
                         line: UInt = #line) throws -> LocalImageDataLoader {
        let store = try CoreDataImageDataStore(storeURL: storeURLForTest())
        let sut = LocalImageDataLoader(store: store, currentDate: currentDate)
        trackForMemoryLeaks(store, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    private func deleteStoreArtifacts() async {
        try? FileManager.default.removeItem(at: storeURLForTest())
        try? await Task.sleep(for: .seconds(0.01)) // Give a little bit time buffer for delete store artefacts
    }
    
    private func storeURLForTest() -> URL {
        let cachesDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        return cachesDirectory.appending(path: "\(type(of: self)).store")
    }
    
}
