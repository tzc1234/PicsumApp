//
//  PhotosLoader.swift
//  PicsumApp
//
//  Created by Tsz-Lung on 03/07/2023.
//

import Foundation

protocol PhotosLoader {
    func load(page: Int) async throws -> [Photo]
}
