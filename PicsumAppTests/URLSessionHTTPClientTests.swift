//
//  URLSessionHTTPClientTests.swift
//  PicsumAppTests
//
//  Created by Tsz-Lung on 06/07/2023.
//

import XCTest
@testable import PicsumApp

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
        let anyError = anyNSError()
        
        await assertFailureFor(data: nil, response: nil, error: anyError)
    }
    
    func test_get_failsOnAllInvalidRepresentationCase() async {
        await assertFailureFor(data: nil, response: nonHTTPURLResponse(), error: nil)
        await assertFailureFor(data: anyData(), response: nil, error: anyNSError())
        await assertFailureFor(data: nil, response: nonHTTPURLResponse(), error: anyNSError())
        await assertFailureFor(data: nil, response: anyHTTPURLResponse(), error: anyNSError())
        await assertFailureFor(data: anyData(), response: nonHTTPURLResponse(), error: anyNSError())
        await assertFailureFor(data: anyData(), response: anyHTTPURLResponse(), error: anyNSError())
        await assertFailureFor(data: anyData(), response: nonHTTPURLResponse(), error: nil)
    }
    
    func test_get_succeedsOnHTTPURLReponseWithData() async throws {
        let sut = makeSUT()
        let data = anyData()
        let response = anyHTTPURLResponse()
        URLProtocolStub.stub(data: data, response: response, error: nil)
        
        let received = try await sut.get(from: anyURL())
        
        XCTAssertEqual(received.0, data)
        XCTAssertEqual(received.1.url, response.url)
        XCTAssertEqual(received.1.statusCode, response.statusCode)
    }
    
    func test_get_succeedsOnHTTPURLReponseWithNilData() async throws {
        let sut = makeSUT()
        let response = anyHTTPURLResponse()
        URLProtocolStub.stub(data: nil, response: response, error: nil)
        
        let received = try await sut.get(from: anyURL())
        
        let emptyData = Data()
        XCTAssertEqual(received.0, emptyData)
        XCTAssertEqual(received.1.url, response.url)
        XCTAssertEqual(received.1.statusCode, response.statusCode)
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
    
    private func assertFailureFor(data: Data?, response: URLResponse?, error: Error?,
                                  file: StaticString = #filePath, line: UInt = #line) async {
        let sut = makeSUT(file: file, line: line)
        URLProtocolStub.stub(data: data, response: response, error: error)
        
        do {
            _ = try await sut.get(from: anyURL())
            XCTFail("Should not success", file: file, line: line)
        } catch {
            XCTAssertNotNil(error, file: file, line: line)
        }
    }
    
    private func anyData() -> Data {
        Data("any data".utf8)
    }
    
    private func anyHTTPURLResponse() -> HTTPURLResponse {
        HTTPURLResponse(statusCode: 200)
    }
    
    private func nonHTTPURLResponse() -> URLResponse {
        URLResponse(url: anyURL(), mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
    }
    
    private class URLProtocolStub: URLProtocol {
        private static let queue = DispatchQueue(label: "URLProtocolStub.queue")
        private static var _stub: Stub?
        private static var stub: Stub? {
            get { queue.sync { _stub } }
            set { queue.sync { _stub = newValue } }
        }
        
        static func stub(data: Data?, response: URLResponse?, error: Error?) {
            stub = .init(data: data, response: response, error: error, requestObserver: nil)
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
            if let data = Self.stub?.data {
                client?.urlProtocol(self, didLoad: data)
            }
            
            if let response = Self.stub?.response {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            
            if let error = Self.stub?.error {
                client?.urlProtocol(self, didFailWithError: error)
            } else {
                client?.urlProtocolDidFinishLoading(self)
            }
            
            Self.stub?.requestObserver?(request)
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
