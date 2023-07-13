//
//  ImageDataLoaderWithFallbackComposite.swift
//  PicsumApp
//
//  Created by Tsz-Lung on 13/07/2023.
//

import Foundation

final class ImageDataLoaderWithFallbackComposite: ImageDataLoader {
    private let primary: ImageDataLoader
    private let fallback: ImageDataLoader
    
    init(primary: ImageDataLoader, fallback: ImageDataLoader) {
        self.primary = primary
        self.fallback = fallback
    }
    
    func loadImageData(for url: URL) async throws -> Data {
        do {
            return try await primary.loadImageData(for: url)
        } catch {
            return try await fallback.loadImageData(for: url)
        }
    }
}
