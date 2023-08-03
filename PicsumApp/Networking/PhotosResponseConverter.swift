//
//  PhotosResponseConverter.swift
//  PicsumApp
//
//  Created by Tsz-Lung on 06/07/2023.
//

import Foundation

enum PhotosResponseConverter {
    enum Error: Swift.Error {
        case invalidData
    }
    
    static func convert(from data: Data, response: HTTPURLResponse) throws -> [Photo] {
        guard response.isOK else {
            throw Error.invalidData
        }
        
        do {
            let remotePhotos = try JSONDecoder().decode([RemotePhoto].self, from: data)
            return remotePhotos.map(\.photo)
        } catch {
            throw Error.invalidData
        }
    }
    
    private struct RemotePhoto: Decodable {
        let id, author: String
        let width, height: Int
        let url, download_url: URL
        
        var photo: Photo {
            .init(id: id, author: author, width: width, height: height, webURL: url, url: download_url)
        }
    }
}
