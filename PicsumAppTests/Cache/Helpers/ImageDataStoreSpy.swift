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
    
    enum Message: Equatable {
        case retrieve(URL)
    }
    
    private(set) var messages = [Message]()
    
    private var retrieveStubs: [RetrieveStub]
    
    init(retrieveStubs: [RetrieveStub]) {
        self.retrieveStubs = retrieveStubs
    }
    
    func retrieve(for url: URL) async throws -> (data: Data, timestamp: Date)? {
        messages.append(.retrieve(url))
        return try retrieveStubs.removeFirst().get()
    }
}
