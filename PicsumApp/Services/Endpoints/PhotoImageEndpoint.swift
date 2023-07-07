//
//  PhotoImageEndpoint.swift
//  PicsumApp
//
//  Created by Tsz-Lung on 07/07/2023.
//

import Foundation

enum PhotoImageEndpoint {
    case get(id: String, width: UInt, height: UInt)
    
    var url: URL {
        switch self {
        case .get:
            return makeURL()
        }
    }
    
    private var scheme: String { "https" }
    private var baseURL: String { "picsum.photos" }
    private var path: String {
        switch self {
        case let .get(id, width, height):
            return "/id/\(id)/\(width)/\(height)"
        }
    }
    
    private func makeURL() -> URL {
        var components = URLComponents()
        components.scheme = scheme
        components.host = baseURL
        components.path = path
        return components.url!
    }
}
