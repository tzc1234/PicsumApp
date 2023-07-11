//
//  LocalImageDataLoader.swift
//  PicsumApp
//
//  Created by Tsz-Lung on 10/07/2023.
//

import Foundation

final class LocalImageDataLoader {
    private let store: ImageDataStore
    private let currentDate: () -> Date
    
    init(store: ImageDataStore, currentDate: @escaping () -> Date = Date.init) {
        self.store = store
        self.currentDate = currentDate
    }
}

extension LocalImageDataLoader: ImageDataLoader {
    enum LoadError: Error {
        case failed
        case notFound
    }
    
    func loadImageData(for url: URL) async throws -> Data {
        do {
            guard let result = try await store.retrieve(for: url),
                  CacheImageDataPolicy.validate(timestamp: result.timestamp, against: currentDate()) else {
                throw LoadError.notFound
            }
            
            return result.data
        } catch {
            throw (error as? LoadError) == .notFound ? LoadError.notFound : LoadError.failed
        }
    }
}

extension LocalImageDataLoader {
    enum SaveError: Error {
        case failed
        case oldDataRemovalFailed
    }
    
    func save(data: Data, for url: URL) async throws {
        do {
            try await store.deleteData(for: url)
        } catch {
            throw SaveError.oldDataRemovalFailed
        }
        
        do {
            try await store.insert(data: data, timestamp: currentDate(), for: url)
        } catch {
            throw SaveError.failed
        }
    }
}

enum CacheImageDataPolicy {
    private static let calendar = Calendar(identifier: .gregorian)
    
    private static var maxCacheDays: Int { 7 }
    
    static func validate(timestamp: Date, against date: Date) -> Bool {
        guard let maxCacheAge = calendar.date(byAdding: .day, value: maxCacheDays, to: timestamp) else {
            return false
        }
        
        return maxCacheAge > date
    }
}
