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
            guard let data = try await store.retrieveData(for: url) else {
                throw LoadError.notFound
            }
            
            return data
        } catch(let loadError as LoadError) {
            throw loadError
        } catch {
            throw LoadError.failed
        }
    }
}

extension LocalImageDataLoader: ImageDataCache {
    enum SaveError: Error {
        case failed
    }
    
    func save(data: Data, for url: URL) async throws {
        do {
            try await store.insert(data: data, timestamp: currentDate(), for: url)
        } catch {
            throw SaveError.failed
        }
    }
}

extension LocalImageDataLoader {
    enum InvalidateError: Error {
        case failed
    }
    
    func invalidateImageData() async throws {
        do {
            let expirationDate = CacheImageDataPolicy.expirationDate(from: currentDate())
            try await store.deleteAllData(reach: expirationDate)
        } catch {
            throw InvalidateError.failed
        }
    }
}
