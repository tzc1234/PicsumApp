//
//  PhotosLoader.swift
//  PicsumApp
//
//  Created by Tsz-Lung on 03/07/2023.
//

import Foundation

protocol PhotosLoader {
    func load(for url: URL) async throws -> [Photo]
}
