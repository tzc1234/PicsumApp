//
//  InMemoryImageDataStore.swift
//  PicsumAppTests
//
//  Created by Tsz-Lung on 05/01/2024.
//

import Foundation
@testable import PicsumApp

final class InMemoryImageDataStore: ImageDataStore {
    typealias Cache = (data: Data, timestamp: Date)
    
    private(set) var imageCache: [URL: Cache] = [:]
    
    private init(cache: (data: Data, timestamp: Date, url: URL)? = nil) {
        cache.map { self.imageCache[$0.url] = ($0.data, $0.timestamp) }
    }
    
    func retrieveData(for url: URL) async throws -> Data? {
        imageCache[url]?.data
    }
    
    func insert(data: Data, timestamp: Date, for url: URL) async throws {
        imageCache[url] = (data, timestamp)
    }
    
    func deleteAllData(until date: Date) async throws {
        imageCache = imageCache.filter { _, cache in cache.timestamp > date }
    }
    
    static var empty: InMemoryImageDataStore {
        .init()
    }
    
    static var withExpiredCache: InMemoryImageDataStore {
        .init(cache: (anyData(), Date.distantPast, anyURL()))
    }
    
    static var withNonExpiredCache: InMemoryImageDataStore {
        .init(cache: (anyData(), Date.distantFuture, anyURL()))
    }
}
