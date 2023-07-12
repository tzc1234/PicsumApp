//
//  CoreDataImageDataStore.swift
//  PicsumApp
//
//  Created by Tsz-Lung on 12/07/2023.
//

import CoreData

final class CoreDataImageDataStore {
    private let container: NSPersistentContainer
    private let context: NSManagedObjectContext
    
    enum StoreError: Error {
        case modelNotFound
        case loadContainerFailed
    }
    
    init(storeURL: URL) throws {
        do {
            self.container = try Self.loadContainer(for: storeURL)
            self.context = container.newBackgroundContext()
        } catch {
            throw StoreError.loadContainerFailed
        }
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
    
    private static let modelName = "DataStore"
    
    private static func loadContainer(for storeURL: URL) throws -> NSPersistentContainer {
        let description = NSPersistentStoreDescription(url: storeURL)
        let container = NSPersistentContainer(name: modelName, managedObjectModel: try loadModel())
        container.persistentStoreDescriptions = [description]
        
        var loadError: Error?
        container.loadPersistentStores { loadError = $1 }
        try loadError.map { throw $0 }
        
        return container
    }
    
    private static func loadModel() throws -> NSManagedObjectModel {
        guard let model = Bundle.main.url(forResource: modelName, withExtension: "momd")
            .flatMap({ NSManagedObjectModel(contentsOf: $0) }) else {
                throw StoreError.modelNotFound
            }
        return model
    }
}
