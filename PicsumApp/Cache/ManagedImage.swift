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
    static func find(in context: NSManagedObjectContext, for url: URL) throws -> ManagedImage? {
        let request = NSFetchRequest<ManagedImage>(entityName: entity().name!)
        request.predicate = NSPredicate(format: "url = %@", url as CVarArg)
        request.returnsObjectsAsFaults = false
        request.fetchLimit = 1
        return try context.fetch(request).first
    }
}
