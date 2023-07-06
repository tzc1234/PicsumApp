//
//  PhotosResponseConverter.swift
//  PicsumApp
//
//  Created by Tsz-Lung on 06/07/2023.
//

import Foundation

enum PhotosResponseConverter {
    enum Error: Swift.Error {
        case invaildData
    }
    
    static func convert(from data: Data, response: HTTPURLResponse) throws -> [Photo] {
        guard isOK(response) else { throw Error.invaildData }
        
        do {
            let photosResponse = try JSONDecoder().decode([PhotoResponse].self, from: data)
            return photosResponse.map(\.photo)
        } catch {
            throw Error.invaildData
        }
    }
    
    private static func isOK(_ response: HTTPURLResponse) -> Bool {
        response.statusCode == 200
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
