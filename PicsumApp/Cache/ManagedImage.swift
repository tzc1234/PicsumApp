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
