//
//  PhotosResponseConverter.swift
//  PicsumApp
//
//  Created by Tsz-Lung on 06/07/2023.
//

import Foundation

enum PhotosResponseConverter {
    private struct RemotePhoto: Decodable {
        let id: String
        let author: String
        let width: Int
        let height: Int
        let url: URL
        let download_url: URL
        
        var photo: Photo {
            .init(id: id, author: author, width: width, height: height, webURL: url, url: download_url)
        }
    }
    
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
}
