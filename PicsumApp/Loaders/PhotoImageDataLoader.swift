//
//  PhotoImageDataLoader.swift
//  PicsumApp
//
//  Created by Tsz-Lung on 04/07/2023.
//

import Foundation

protocol PhotoImageDataLoader {
    func loadImageData(by id: String, width: Int, height: Int) async throws -> Data
}
