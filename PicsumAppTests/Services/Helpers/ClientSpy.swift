//
//  ClientSpy.swift
//  PicsumAppTests
//
//  Created by Tsz-Lung on 06/07/2023.
//

import Foundation
@testable import PicsumApp

class ClientSpy: HTTPClient {
    typealias Stub = Result<(Data, HTTPURLResponse), Error>
    
    private(set) var loggedURLs = [URL]()
    
    private var stubs: [Stub]
    
    init(stubs: [Stub]) {
        self.stubs = stubs
    }
    
    func get(from url: URL) async throws -> (Data, HTTPURLResponse) {
        loggedURLs.append(url)
        return try stubs.removeFirst().get()
    }
}
