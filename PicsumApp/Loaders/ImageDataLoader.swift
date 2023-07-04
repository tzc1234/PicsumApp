//
//  ImageDataLoader.swift
//  PicsumApp
//
//  Created by Tsz-Lung on 04/07/2023.
//

import Foundation

protocol ImageDataLoader {
    func loadImageData(from url: URL) async throws -> Data
}
