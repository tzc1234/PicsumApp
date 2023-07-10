//
//  RemoteImageDataLoader.swift
//  PicsumApp
//
//  Created by Tsz-Lung on 06/07/2023.
//

import Foundation

protocol ImageDataLoader {
    func loadImageData(for url: URL) async throws -> Data
}

final class RemoteImageDataLoader: ImageDataLoader {
    private let client: HTTPClient
    
    init(client: HTTPClient) {
        self.client = client
    }
    
    enum Error: Swift.Error {
        case invalidData
    }
    
    func loadImageData(for url: URL) async throws -> Data {
        do {
            let (data, response) = try await client.get(from: url)
            guard response.statusCode == 200 else { throw Error.invalidData }
            
            return data
        } catch {
            throw Error.invalidData
        }
    }
}
