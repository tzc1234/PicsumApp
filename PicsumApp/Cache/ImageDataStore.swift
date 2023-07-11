//
//  ImageDataStore.swift
//  PicsumApp
//
//  Created by Tsz-Lung on 10/07/2023.
//

import Foundation

protocol ImageDataStore {
    func retrieve(for url: URL) async throws -> (data: Data, timestamp: Date)?
    func deleteData(for url: URL) async throws
}
