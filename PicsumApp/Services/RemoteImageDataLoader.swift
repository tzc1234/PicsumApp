//
//  RemoteImageDataLoader.swift
//  PicsumApp
//
//  Created by Tsz-Lung on 06/07/2023.
//

import Foundation

final class RemoteImageDataLoader: ImageDataLoader {
    private let client: HTTPClient
    
    init(client: HTTPClient) {
        self.client = client
    }
    
    enum Error: Swift.Error {
        case invalidData
    }
    
    func loadImageData(by id: String, width: UInt, height: UInt) async throws -> Data {
        do {
            let url = PhotoImageEndpoint.get(id: id, width: width, height: height).url
            let (data, response) = try await client.get(from: url)
            guard response.statusCode == 200 else { throw Error.invalidData }
            
            return data
        } catch {
            throw Error.invalidData
        }
    }
}
