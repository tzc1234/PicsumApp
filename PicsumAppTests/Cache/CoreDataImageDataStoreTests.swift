//
//  CoreDataImageDataStoreTests.swift
//  PicsumAppTests
//
//  Created by Tsz-Lung on 12/07/2023.
//

import CoreData
import XCTest
@testable import PicsumApp

class CoreDataImageDataStore {
    private let container: NSPersistentContainer
    private let context: NSManagedObjectContext
    
    init() throws {
        let modelName = "DataStore"
        let modelURL = Bundle.main.url(forResource: modelName, withExtension: "momd")
        let model = NSManagedObjectModel(contentsOf: modelURL!)
        
        let storeURL = URL(filePath: "/dev/null")
        let description = NSPersistentStoreDescription(url: storeURL)
        let container = NSPersistentContainer(name: modelName, managedObjectModel: model!)
        container.persistentStoreDescriptions = [description]
        
        var loadError: Error?
        container.loadPersistentStores { loadError = $1 }
        try loadError.map { throw $0 }
        
        self.container = container
        self.context = container.newBackgroundContext()
    }
    
    func retrieveData(for url: URL) async throws -> Data? {
        let context = self.context
        return try await context.perform {
            let request = NSFetchRequest<ManagedImage>(entityName: "ManagedImage")
            request.predicate = NSPredicate(format: "url = %@", url as CVarArg)
            request.returnsObjectsAsFaults = false
            request.fetchLimit = 1
            let image = try context.fetch(request).first
            
            return image?.data
        }
    }
    
    func insert(data: Data, timestamp: Date, for url: URL) async throws {
        let context = self.context
        try await context.perform {
            let image = ManagedImage(context: context)
            image.data = data
            image.timestamp = timestamp
            image.url = url
            try context.save()
        }
    }
}

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
        let notificationSpy = ContextDidSaveNotificationSpy()
        let url = anyURL()
        let data = anyData()
        
        try await sut.insert(data: data, timestamp: anyTimestamp(), for: url)
        let retrievedData = try await sut.retrieveData(for: url)
            
        XCTAssertEqual(notificationSpy.saveCount, 1)
        XCTAssertEqual(retrievedData, data)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) throws -> CoreDataImageDataStore {
        let sut = try CoreDataImageDataStore()
        trackForMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    private func anyTimestamp() -> Date {
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
