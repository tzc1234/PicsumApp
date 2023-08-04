//
//  ImageDataStoreSpy.swift
//  PicsumAppTests
//
//  Created by Tsz-Lung on 10/07/2023.
//

import Foundation
@testable import PicsumApp

class ImageDataStoreSpy: ImageDataStore {
    typealias RetrieveDataStub = Result<Data?, Error>
    typealias InsertStub = Result<Void, Error>
    typealias DeleteAllDataStub = Result<Void, Error>
    
    enum Message: Equatable {
        case retrieveData(URL)
        case insert(URL)
        case deleteAllData
    }
    
    struct Inserted: Equatable {
        let data: Data
        let timestamp: Date
    }
    
    private(set) var messages = [Message]()
    private(set) var insertedData = [Inserted]()
    private(set) var datesForDeleteAllData = [Date]()
    
    private var retrieveStubs: [RetrieveDataStub]
    private var insertStubs: [InsertStub]
    private var deleteAllDataStubs: [DeleteAllDataStub]
    
    init(retrieveDataStubs: [RetrieveDataStub], insertStubs: [InsertStub], deleteAllDataStubs: [DeleteAllDataStub]) {
        self.retrieveStubs = retrieveDataStubs
        self.insertStubs = insertStubs
        self.deleteAllDataStubs = deleteAllDataStubs
    }
    
    func retrieveData(for url: URL) async throws -> Data? {
        messages.append(.retrieveData(url))
        return try retrieveStubs.removeFirst().get()
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
    
    func deleteAllData(until date: Date) async throws {
        messages.append(.deleteAllData)
        datesForDeleteAllData.append(date)
        try deleteAllDataStubs.removeFirst().get()
    }
}
