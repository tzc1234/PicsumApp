//
//  ManagedImage.swift
//  PicsumApp
//
//  Created by Tsz-Lung on 12/07/2023.
//

import CoreData

@objc(ManagedImage)
final class ManagedImage: NSManagedObject {
    @NSManaged var data: Data
    @NSManaged var timestamp: Date
    @NSManaged var url: URL
}

extension ManagedImage {
    static var entityName: String {
        String(describing: Self.self)
    }
    
    static func find(in context: NSManagedObjectContext, for url: URL) throws -> ManagedImage? {
        let request = NSFetchRequest<ManagedImage>(entityName: entityName)
        request.predicate = NSPredicate(format: "url = %@", url as CVarArg)
        request.returnsObjectsAsFaults = false
        request.fetchLimit = 1
        return try context.fetch(request).first
    }
    
    static func findOrNewInstance(in context: NSManagedObjectContext, for url: URL) throws -> ManagedImage {
        let foundImage = try ManagedImage.find(in: context, for: url)
        return foundImage ?? ManagedImage(context: context)
    }
    
    static func batchDelete(in context: NSManagedObjectContext, reach date: Date) throws {
        let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        fetch.predicate = NSPredicate(format: "timestamp <= %@", date as CVarArg)
        let request = NSBatchDeleteRequest(fetchRequest: fetch)
        try context.execute(request)
    }
}
