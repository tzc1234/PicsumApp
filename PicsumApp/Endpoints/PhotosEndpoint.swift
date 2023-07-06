//
//  PhotosEndpoint.swift
//  PicsumApp
//
//  Created by Tsz-Lung on 06/07/2023.
//

import Foundation

enum PhotosEndpoint {
    case get(page: Int)
    
    var url: URL {
        switch self {
        case .get:
            return makeURL()
        }
    }
    
    private var scheme: String { "https" }
    private var baseURL: String { "picsum.photos" }
    private var path: String { "/v2/list" }
    private var queryItems: [URLQueryItem] {
        switch self {
        case .get(let page):
            return [.init(name: "page", value: "\(page)")]
        }
    }
    
    private func makeURL() -> URL {
        var components = URLComponents()
        components.scheme = scheme
        components.host = baseURL
        components.path = path
        components.queryItems = queryItems
        return components.url!
    }
}
