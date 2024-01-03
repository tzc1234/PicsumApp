//
//  LocalImageDataCacheIntegrationTests.swift
//  PicsumAppTests
//
//  Created by Tsz-Lung on 17/07/2023.
//

/*
 Got this error from this test if instantiate more than one ModelContainer with same URL upfront:
 Error Domain=NSCocoaErrorDomain Code=134020 "The model configuration used to open the store is incompatible with the
 one that was used to create the store."
 See can find any better solution later.
 */

import XCTest
import SwiftData
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
        let data = anyData()
        let url = anyURL()
        
        let imageLoaderForSave = try makeSUT()
        try await imageLoaderForSave.save(data: data, for: url)
        
        let imageLoaderForLoad = try makeSUT()
        let receivedData = try await imageLoaderForLoad.loadImageData(for: url)
        
        XCTAssertEqual(receivedData, data)
    }
    
    func test_save_overridesSavedDataOnASeparateInstance() async throws {
        let firstData = Data("first data".utf8)
        let lastData = Data("last data".utf8)
        let url = anyURL()
        
        let imageLoaderForFirstSave = try makeSUT()
        try await imageLoaderForFirstSave.save(data: firstData, for: url)
        
        let imageLoaderForLastSave = try makeSUT()
        try await imageLoaderForLastSave.save(data: lastData, for: url)
        
        let imageLoaderForLoad = try makeSUT()
        let receivedData = try await imageLoaderForLoad.loadImageData(for: url)
        
        XCTAssertEqual(receivedData, lastData)
    }
    
    func test_invalidateImageData_removesAllSavedDataInADistancePast() async throws {
        let data = anyData()
        let url = anyURL()
        
        let imageLoaderForSave = try makeSUT(currentDate: { .distantPast })
        try await imageLoaderForSave.save(data: data, for: url)
        
        let imageLoaderForInvalidate = try makeSUT(currentDate: { .now })
        try await imageLoaderForInvalidate.invalidateImageData()
        
        let imageLoaderForLoad = try makeSUT()
        await asyncAssertThrowsError(_ = try await imageLoaderForLoad.loadImageData(for: url))
    }

    // MARK: - Helpers
    
    private func makeSUT(currentDate: @escaping () -> Date = Date.init,
                         file: StaticString = #filePath,
                         line: UInt = #line) throws -> LocalImageDataLoader {
        let store = try SwiftDataImageDataStore(url: storeURLForTest())
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
