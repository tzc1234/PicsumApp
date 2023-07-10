//
//  ImageDataLoader.swift
//  PicsumApp
//
//  Created by Tsz-Lung on 10/07/2023.
//

import Foundation

protocol ImageDataLoader {
    func loadImageData(for url: URL) async throws -> Data
}
