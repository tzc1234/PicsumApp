//
//  CoreDataImageDataStore.swift
//  PicsumApp
//
//  Created by Tsz-Lung on 12/07/2023.
//

import CoreData

final class CoreDataImageDataStore: ImageDataStore {
    private let container: NSPersistentContainer
    private let context: NSManagedObjectContext
    
    init(storeURL: URL) throws {
        self.container = try Self.loadContainer(for: storeURL)
        self.context = container.newBackgroundContext()
    }
    
    func retrieveData(for url: URL) async throws -> Data? {
        try await perform { context in
            try ManagedImage.find(in: context, for: url)?.data
        }
    }
    
    func insert(data: Data, timestamp: Date, for url: URL) async throws {
        try await perform { context in
            let image = try ManagedImage.findOrCreateInstance(in: context, for: url)
            image.data = data
            image.timestamp = timestamp
            image.url = url
            try context.save()
        }
    }
    
    func deleteData(for url: URL) async throws {
        try await perform { context in
            try ManagedImage.find(in: context, for: url)
                .map(context.delete)
                .map(context.save)
        }
    }
    
    func deleteAllData(reach date: Date) async throws {
        try await perform { context in
            try ManagedImage.batchDelete(in: context, reach: date)
        }
    }
    
    private func perform<T>(_ action: @escaping (NSManagedObjectContext) throws -> T) async rethrows -> T {
        try await context.perform { [context] in
            try action(context)
        }
    }
}

extension CoreDataImageDataStore {
    enum StoreError: Error {
        case modelNotFound
        case loadContainerFailed
    }
    
    private static let modelName = "DataStore"
    
    private static func loadContainer(for storeURL: URL) throws -> NSPersistentContainer {
        let container = NSPersistentContainer(name: modelName, managedObjectModel: try loadModel())
        container.persistentStoreDescriptions = [.init(url: storeURL)]
        
        var loadError: Error?
        container.loadPersistentStores { loadError = $1 }
        
        do {
            try loadError.map { throw $0 }
            return container
        } catch {
            throw StoreError.loadContainerFailed
        }
    }
    
    private static func loadModel() throws -> NSManagedObjectModel {
        let bundle = Bundle(for: Self.self)
        guard let model = bundle.url(forResource: modelName, withExtension: "momd")
            .flatMap({ NSManagedObjectModel(contentsOf: $0) }) else {
                throw StoreError.modelNotFound
            }
        return model
    }
}
