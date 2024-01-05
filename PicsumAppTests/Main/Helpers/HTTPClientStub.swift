//
//  HTTPClientStub.swift
//  PicsumAppTests
//
//  Created by Tsz-Lung on 05/01/2024.
//

import Foundation
@testable import PicsumApp

final class HTTPClientStub: HTTPClient {
    typealias Stub = (URL) throws -> (Data, HTTPURLResponse)
    
    private let stub: Stub
    
    init(stub: @escaping Stub) {
        self.stub = stub
    }
    
    func get(from url: URL) async throws -> (Data, HTTPURLResponse) {
        try stub(url)
    }
    
    static var failure: HTTPClientStub {
        .init { _ in throw anyNSError() }
    }
    
    static func success(_ stub: @escaping Stub) -> HTTPClientStub {
        .init(stub: stub)
    }
}
