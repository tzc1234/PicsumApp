//
//  RemoteImageDataLoaderTests.swift
//  PicsumAppTests
//
//  Created by Tsz-Lung on 06/07/2023.
//

import XCTest
@testable import PicsumApp

final class RemoteImageDataLoaderTests: XCTestCase {

    func test_init_doesNotTriggerClient() {
        let (_, client) = makeSUT()
        
        XCTAssertEqual(client.loggedURLs.count, 0)
    }
    
    func test_loadImageData_passesCorrectParametersToClient() async {
        let (sut, client) = makeSUT(stubs: [.failure(anyNSError())])
        let url = URL(string: "https://load-image-url.com")!
        
        _ = try? await sut.loadImageData(for: url)
        
        XCTAssertEqual(client.loggedURLs, [url])
    }
    
    func test_loadImageData_deliversErrorOnClientError() async {
        let (sut, _) = makeSUT(stubs: [.failure(anyNSError())])
        
        await asyncAssertThrowsError(_ = try await sut.loadImageData(for: anyURL())) { error in
            assertInvalidDataError(error)
        }
    }
    
    func test_loadImageData_deliversErrorWhenNon200Response() async {
        let simples = [100, 201, 202, 300, 400, 500]
        let stubs = simples.map { ClientSpy.Stub.success((Data(), HTTPURLResponse(statusCode: $0))) }
        let (sut, _) = makeSUT(stubs: stubs)
        
        for statusCode in simples {
            await asyncAssertThrowsError(
                _ = try await sut.loadImageData(for: anyURL()),
                "Should not success in statusCode: \(statusCode)") { error in
                    assertInvalidDataError(error)
                }
        }
    }
    
    func test_loadImageData_deliversDataWhen200Response() async throws {
        let imageData = UIImage.makeData(withColor: .red)
        let (sut, _) = makeSUT(stubs: [.success((imageData, .ok200Response))])
        
        let data = try await sut.loadImageData(for: anyURL())
        
        XCTAssertEqual(data, imageData)
    }

    // MARK: - Helpers
    
    private func makeSUT(stubs: [ClientSpy.Stub] = [],
                         file: StaticString = #filePath,
                         line: UInt = #line) -> (sut: RemoteImageDataLoader, client: ClientSpy) {
        let client = ClientSpy(stubs: stubs)
        let sut = RemoteImageDataLoader(client: client)
        
        trackForMemoryLeaks(client, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        
        return (sut, client)
    }
    
    private func assertInvalidDataError(_ error: Error, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(error as? RemoteImageDataLoader.Error, .invalidData, file: file, line: line)
    }
    
}
