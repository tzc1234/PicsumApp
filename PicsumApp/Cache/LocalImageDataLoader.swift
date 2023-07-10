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
    
    enum LoadError: Error {
        case failed
        case notFound
    }
    
    func loadImageData(for url: URL) async throws -> Data {
        do {
            guard let result = try await store.retrieve(for: url) else {
                throw LoadError.notFound
            }
            
            let maxCacheAge = Calendar(identifier: .gregorian).date(byAdding: .day, value: 7, to: result.timestamp)
            
            guard let maxCacheAge, maxCacheAge > currentDate() else {
                throw LoadError.notFound
            }
            
            return result.data
        } catch {
            throw (error as? LoadError) == .notFound ? LoadError.notFound : LoadError.failed
        }
    }
}
