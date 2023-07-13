//
//  ImageDataCache.swift
//  PicsumApp
//
//  Created by Tsz-Lung on 13/07/2023.
//

import Foundation

protocol ImageDataCache {
    func save(data: Data, for url: URL) async throws
}
