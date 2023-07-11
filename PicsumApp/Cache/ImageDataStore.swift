//
//  ImageDataStore.swift
//  PicsumApp
//
//  Created by Tsz-Lung on 10/07/2023.
//

import Foundation

protocol ImageDataStore {
    func retrieve(for url: URL) async throws -> Data?
    func insert(data: Data, timestamp: Date, for url: URL) async throws
    func deleteData(for url: URL) async throws
    func deleteAllData(reach date: Date) async throws
}
