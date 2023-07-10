//
//  PhotoImageDataLoaderAdapter.swift
//  PicsumApp
//
//  Created by Tsz-Lung on 10/07/2023.
//

import Foundation

final class PhotoImageDataLoaderAdapter: PhotoImageDataLoader {
    private let loader: ImageDataLoader
    
    init(imageDataLoader: ImageDataLoader) {
        self.loader = imageDataLoader
    }
    
    func loadImageData(by id: String, width: Int, height: Int) async throws -> Data {
        let url = PhotoImageEndpoint.get(id: id, width: width, height: height).url
        return try await loader.loadImageData(for: url)
    }
}
