//
//  RemotePhotosLoader.swift
//  PicsumApp
//
//  Created by Tsz-Lung on 06/07/2023.
//

import Foundation

final class RemotePhotosLoader: PhotosLoader {
    private let client: HTTPClient
    
    init(client: HTTPClient) {
        self.client = client
    }
    
    func load(for url: URL) async throws -> [Photo] {
        do {
            let (data, response) = try await client.get(from: url)
            return try PhotosResponseConverter.convert(from: data, response: response)
        } catch {
            throw PhotosResponseConverter.Error.invalidData
        }
    }
}
