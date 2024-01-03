//
//  SwiftDataImageDataStore.swift
//  PicsumApp
//
//  Created by Tsz-Lung on 02/01/2024.
//

import Foundation
import SwiftData

@Model
final class SwiftDataImage {
    var data: Data
    var timestamp: Date
    @Attribute(.unique) var url: String
    
    init(data: Data, timestamp: Date, url: URL) {
        self.data = data
        self.timestamp = timestamp
        self.url = url.absoluteString
    }
}

final actor SwiftDataImageDataStore: ModelActor, ImageDataStore {
    let modelContainer: ModelContainer
    let modelExecutor: ModelExecutor
    
    init(configuration: ModelConfiguration) throws {
        self.modelContainer = try ModelContainer(for: SwiftDataImage.self, configurations: configuration)
        self.modelExecutor = DefaultSerialModelExecutor(modelContext: ModelContext(modelContainer))
    }
    
    func retrieveData(for url: URL) throws -> Data? {
        let predicate = #Predicate<SwiftDataImage> { $0.url == url.absoluteString }
        var descriptor = FetchDescriptor<SwiftDataImage>(predicate: predicate)
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first?.data
    }
    
    func insert(data: Data, timestamp: Date, for url: URL) throws {
        modelContext.insert(SwiftDataImage(data: data, timestamp: timestamp, url: url))
        try modelContext.save()
    }
    
    func deleteAllData(until date: Date) throws {
        let predicate = #Predicate<SwiftDataImage> { $0.timestamp <= date }
        try modelContext.delete(model: SwiftDataImage.self, where: predicate)
    }
    
    deinit {
        modelContainer.deleteAllData()
    }
}
