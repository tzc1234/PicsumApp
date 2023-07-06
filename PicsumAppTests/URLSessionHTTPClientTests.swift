//
//  URLSessionHTTPClientTests.swift
//  PicsumAppTests
//
//  Created by Tsz-Lung on 06/07/2023.
//

import XCTest
@testable import PicsumApp

class URLSessionHTTPClient: HTTPClient {
    private let session: URLSession
    
    init(session: URLSession) {
        self.session = session
    }
    
    func get(from url: URL) async throws -> (Data, HTTPURLResponse) {
        let _ = try await session.data(from: url)
        throw anyNSError()
    }
}

final class URLSessionHTTPClientTests: XCTestCase {

    override func tearDown() {
        super.tearDown()
        
        URLProtocolStub.reset()
    }
    
    func test_get_ensuresRequestURLAndMethodCorrect() async {
        let sut = makeSUT()
        let url = anyURL()
        
        let exp = expectation(description: "wait for request")
        URLProtocolStub.observeRequest { request in
            XCTAssertEqual(request.url, url)
            XCTAssertEqual(request.httpMethod, "GET")
            exp.fulfill()
        }
        
        _ = try? await sut.get(from: url)
        
        await fulfillment(of: [exp])
    }
    
    func test_get_failsOnRequestError() async {
        let sut = makeSUT()
        let expectedError = anyNSError()
        URLProtocolStub.stub(error: expectedError)
        
        do {
            _ = try await sut.get(from: anyURL())
            XCTFail("Should not success")
        } catch {
            XCTAssertNotNil(error)
        }
    }
    
    // MARK: - Helpers
    
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> URLSessionHTTPClient {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        let session = URLSession(configuration: configuration)
        let sut = URLSessionHTTPClient(session: session)
        
        trackForMemoryLeaks(sut, file: file, line: line)
        
        return sut
    }
    
    private class URLProtocolStub: URLProtocol {
        private static let queue = DispatchQueue(label: "URLProtocolStub.queue")
        private static var _stub: Stub?
        private static var stub: Stub? {
            get { queue.sync { _stub } }
            set { queue.sync { _stub = newValue } }
        }
        
        static func stub(error: Error? = nil) {
            stub = .init(data: nil, response: nil, error: error, requestObserver: nil)
        }
        
        static func observeRequest(observer: @escaping (URLRequest) -> Void) {
            stub = .init(data: nil, response: nil, error: anyNSError(), requestObserver: observer)
        }
        
        static func reset() {
            stub = nil
        }
        
        override class func canInit(with request: URLRequest) -> Bool {
            true
        }
        
        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            request
        }
        
        override func startLoading() {
            guard let stub = Self.stub else { return }
            
            if let error = stub.error {
                client?.urlProtocol(self, didFailWithError: error)
            } else {
                client?.urlProtocolDidFinishLoading(self)
            }
            
            stub.requestObserver?(request)
        }
        
        override func stopLoading() {}
        
        private struct Stub {
            let data: Data?
            let response: URLResponse?
            let error: Error?
            let requestObserver: ((URLRequest) -> Void)?
        }
    }

}
