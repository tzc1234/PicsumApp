//
//  PhotoImageDataLoaderAdapterTests.swift
//  PicsumAppTests
//
//  Created by Tsz-Lung on 10/07/2023.
//

import XCTest
@testable import PicsumApp

final class PhotoImageDataLoaderAdapterTests: XCTestCase {

    func test_init_noTriggerLoader() {
        let (_, loader) = makeSUT()
        
        XCTAssertEqual(loader.loggedURLs.count, 0)
    }
    
    func test_loadImageData_passesCorrectURLToLoader() async {
        let (sut, loader) = makeSUT(stubs: [.failure(anyNSError())])
        let id = "99"
        let width = 100
        let height = 200
        
        _ = try? await sut.loadImageData(by: id, width: width, height: height)
        
        let expectedURL = PhotoImageEndpoint.get(id: id, width: width, height: height).url
        XCTAssertEqual(loader.loggedURLs, [expectedURL])
    }
    
    func test_loadImageData_deliversErrorOnError() async {
        let (sut, _) = makeSUT(stubs: [.failure(anyNSError())])
        
        do {
            _ = try await sut.loadImageData(by: "1", width: 1, height: 1)
            XCTFail("Should not success")
        } catch {}
    }
    
    func test_loadImageData_deliversDataOnSuccess() async throws {
        let data = anyData()
        let (sut, _) = makeSUT(stubs: [.success(data)])
        
        let receivedData = try await sut.loadImageData(by: "1", width: 1, height: 1)
        
        XCTAssertEqual(receivedData, data)
    }

    // MARK: - Helpers
    
    private func makeSUT(stubs: [RemoteImageDataLoaderSpy.Stub] = [],
                         file: StaticString = #filePath,
                         line: UInt = #line) -> (sut: PhotoImageDataLoaderAdapter, loader: RemoteImageDataLoaderSpy) {
        let loader = RemoteImageDataLoaderSpy(stubs: stubs)
        let sut = PhotoImageDataLoaderAdapter(imageDataLoader: loader)
        
        trackForMemoryLeaks(loader, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        
        return (sut, loader)
    }
    
    private class RemoteImageDataLoaderSpy: ImageDataLoader {
        typealias Stub = Result<Data, Error>
        
        private(set) var loggedURLs = [URL]()
        private var stubs: [Stub]
        
        init(stubs: [Stub]) {
            self.stubs = stubs
        }
        
        func loadImageData(for url: URL) async throws -> Data {
            loggedURLs.append(url)
            return try stubs.removeFirst().get()
        }
    }
    
}
