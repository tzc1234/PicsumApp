//
//  RemoteImageDataLoaderTests.swift
//  PicsumAppTests
//
//  Created by Tsz-Lung on 06/07/2023.
//

import XCTest
@testable import PicsumApp

final class RemoteImageDataLoaderTests: XCTestCase {

    func test_init_noTriggerClient() {
        let (_, client) = makeSUT()
        
        XCTAssertEqual(client.loggedURLs.count, 0)
    }
    
    func test_loadImageData_passesCorrectParametersToClient() async {
        let (sut, client) = makeSUT(stubs: [.failure(anyNSError())])
        let id = "99"
        let width = 500
        let height = 500
        
        _ = try? await sut.loadImageData(by: id, width: width, height: height)
        
        XCTAssertEqual(client.loggedURLs, [PhotoImageEndpoint.get(id: id, width: width, height: height).url])
    }
    
    func test_loadImageData_deliversErrorOnClientError() async {
        let (sut, _) = makeSUT(stubs: [.failure(anyNSError())])
        
        do {
            _ = try await sut.loadImageData(by: "1", width: 1, height: 1)
            XCTFail("Should not success")
        } catch {
            assertInvalidDataError(error)
        }
    }
    
    func test_loadImageData_deliversErrorWhenNon200Response() async {
        let simples = [100, 201, 202, 300, 400, 500]
        let stubs = simples.map { ClientSpy.Stub.success((Data(), HTTPURLResponse(statusCode: $0))) }
        let (sut, _) = makeSUT(stubs: stubs)
        
        for statusCode in simples {
            do {
                _ = try await sut.loadImageData(by: "1", width: 1, height: 1)
                XCTFail("Should not success in statusCode: \(statusCode)")
            } catch {
                assertInvalidDataError(error)
            }
        }
    }
    
    func test_loadImageData_deliversDataWhen200Response() async throws {
        let imageData = UIImage.make(withColor: .red).pngData()!
        let (sut, _) = makeSUT(stubs: [.success((imageData, HTTPURLResponse(statusCode: 200)))])
        
        let data = try await sut.loadImageData(by: "1", width: 1, height: 1)
        
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
