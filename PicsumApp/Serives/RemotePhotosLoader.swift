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
    
    enum Error: Swift.Error {
        case invaildData
    }
    
    func load(page: Int) async throws -> [Photo] {
        do {
            let (data, response) = try await client.get(from: PhotosEndpoint.get(page: page).url)
            guard response.statusCode == 200 else {
                throw Error.invaildData
            }
            
            let photosResponse = try JSONDecoder().decode([PhotoResponse].self, from: data)
            return photosResponse.map(\.photo)
        } catch {
            throw Error.invaildData
        }
    }
    
    private struct PhotoResponse: Decodable {
        let id, author: String
        let width, height: Int
        let url, download_url: URL
        
        var photo: Photo {
            .init(id: id, author: author, width: width, height: height, webURL: url, url: download_url)
        }
    }
}
