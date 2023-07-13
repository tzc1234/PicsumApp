//
//  URLSessionHTTPClient.swift
//  PicsumApp
//
//  Created by Tsz-Lung on 06/07/2023.
//

import Foundation

final class URLSessionHTTPClient: HTTPClient {
    private let session: URLSession
    
    init(session: URLSession) {
        self.session = session
    }
    
    private struct UnexpectedValueRepresentation: Error {}
    
    func get(from url: URL) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await session.data(from: url)
        guard let response = response as? HTTPURLResponse else {
            throw UnexpectedValueRepresentation()
        }
        
        return (data, response)
    }
}
