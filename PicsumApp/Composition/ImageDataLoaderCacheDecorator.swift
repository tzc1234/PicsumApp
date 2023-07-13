//
//  ImageDataLoaderCacheDecorator.swift
//  PicsumApp
//
//  Created by Tsz-Lung on 13/07/2023.
//

import Foundation

final class ImageDataLoaderCacheDecorator: ImageDataLoader {
    private let loader: ImageDataLoader
    private let cache: ImageDataCache
    
    init(loader: ImageDataLoader, cache: ImageDataCache) {
        self.loader = loader
        self.cache = cache
    }
    
    func loadImageData(for url: URL) async throws -> Data {
        let data = try await loader.loadImageData(for: url)
        try? await cache.save(data: data, for: url)
        return data
    }
}
