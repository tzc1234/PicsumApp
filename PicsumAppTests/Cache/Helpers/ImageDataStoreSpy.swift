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
    
    enum Message: Equatable {
        case retrieve(URL)
        case deleteData(URL)
    }
    
    private(set) var messages = [Message]()
    
    private var retrieveStubs: [RetrieveStub]
    private var deleteDataStubs: [DeleteDataStub]
    
    init(retrieveStubs: [RetrieveStub], deleteDataStubs: [DeleteDataStub]) {
        self.retrieveStubs = retrieveStubs
        self.deleteDataStubs = deleteDataStubs
    }
    
    func retrieve(for url: URL) async throws -> (data: Data, timestamp: Date)? {
        messages.append(.retrieve(url))
        return try retrieveStubs.removeFirst().get()
    }
    
    func deleteData(for url: URL) async throws {
        messages.append(.deleteData(url))
        try deleteDataStubs.removeFirst().get()
    }
}
