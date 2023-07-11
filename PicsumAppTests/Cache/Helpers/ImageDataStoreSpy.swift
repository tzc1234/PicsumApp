//
//  ImageDataStoreSpy.swift
//  PicsumAppTests
//
//  Created by Tsz-Lung on 10/07/2023.
//

import Foundation
@testable import PicsumApp

class ImageDataStoreSpy: ImageDataStore {
    typealias RetrieveStub = Result<(Data, Date)?, Error>
    typealias DeleteDataStub = Result<Void, Error>
    typealias InsertStub = Result<Void, Error>
    
    enum Message: Equatable {
        case retrieve(URL)
        case deleteData(URL)
        case insert(URL)
    }
    
    struct Inserted: Equatable {
        let data: Data
        let timestamp: Date
    }
    
    private(set) var messages = [Message]()
    private(set) var insertedData = [Inserted]()
    
    private var retrieveStubs: [RetrieveStub]
    private var deleteDataStubs: [DeleteDataStub]
    private var insertStubs: [InsertStub]
    
    init(retrieveStubs: [RetrieveStub], deleteDataStubs: [DeleteDataStub], insertStubs: [InsertStub]) {
        self.retrieveStubs = retrieveStubs
        self.deleteDataStubs = deleteDataStubs
        self.insertStubs = insertStubs
    }
    
    func retrieve(for url: URL) async throws -> (data: Data, timestamp: Date)? {
        messages.append(.retrieve(url))
        return try retrieveStubs.removeFirst().get()
    }
    
    func deleteData(for url: URL) async throws {
        messages.append(.deleteData(url))
        try deleteDataStubs.removeFirst().get()
    }
    
    func insert(data: Data, timestamp: Date, for url: URL) async throws {
        messages.append(.insert(url))

        do {
            try insertStubs.removeFirst().get()
            insertedData.append(.init(data: data, timestamp: timestamp))
        } catch {
            throw error
        }
    }
}
