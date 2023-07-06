//
//  HTTPClient.swift
//  PicsumApp
//
//  Created by Tsz-Lung on 06/07/2023.
//

import Foundation

protocol HTTPClient {
    func get(from url: URL) async throws -> (Data, HTTPURLResponse)
}
