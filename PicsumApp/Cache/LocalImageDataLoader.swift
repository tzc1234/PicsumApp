//
//  LocalImageDataLoader.swift
//  PicsumApp
//
//  Created by Tsz-Lung on 10/07/2023.
//

import Foundation

final class LocalImageDataLoader {
    private let store: ImageDataStore
    
    init(store: ImageDataStore) {
        self.store = store
    }
    
    enum LoadError: Error {
        case failed
        case notFound
    }
    
    func loadImageData(for url: URL) async throws -> Data {
        do {
            guard let data = try await store.retrieve(for: url) else {
                throw LoadError.notFound
            }
            
            return data
        } catch {
            throw (error as? LoadError) == .notFound ? LoadError.notFound : LoadError.failed
        }
    }
}
