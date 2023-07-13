//
//  ImageDataLoaderWithFallbackCompositeTests.swift
//  PicsumAppTests
//
//  Created by Tsz-Lung on 13/07/2023.
//

import XCTest
@testable import PicsumApp

class ImageDataLoaderWithFallbackComposite: ImageDataLoader {
    private let primary: ImageDataLoader
    private let fallback: ImageDataLoader
    
    init(primary: ImageDataLoader, fallback: ImageDataLoader) {
        self.primary = primary
        self.fallback = fallback
    }
    
    func loadImageData(for url: URL) async throws -> Data {
        do {
            return try await primary.loadImageData(for: url)
        } catch {
            return try await fallback.loadImageData(for: url)
        }
    }
}


final class ImageDataLoaderWithFallbackCompositeTests: XCTestCase {

    func test_loadImageData_deliversDataOnPrimarySuccess() async throws {
        let data = anyData()
        let primary = ImageDataLoaderSpy(stubs: [.success(data)])
        let fallback = ImageDataLoaderSpy(stubs: [.failure(anyNSError())])
        let sut = ImageDataLoaderWithFallbackComposite(primary: primary, fallback: fallback)
        
        let receivedData = try await sut.loadImageData(for: anyURL())
        
        XCTAssertEqual(receivedData, data)
    }
    
    func test_loadImageData_deliversFallbackDataOnPrimaryError() async throws {
        let data = anyData()
        let primary = ImageDataLoaderSpy(stubs: [.failure(anyNSError())])
        let fallback = ImageDataLoaderSpy(stubs: [.success(data)])
        let sut = ImageDataLoaderWithFallbackComposite(primary: primary, fallback: fallback)
        
        let receivedData = try await sut.loadImageData(for: anyURL())
        
        XCTAssertEqual(receivedData, data)
    }
    
    func test_loadImageData_deliversErrorOnBothOnError() async {
        let primary = ImageDataLoaderSpy(stubs: [.failure(anyNSError())])
        let fallback = ImageDataLoaderSpy(stubs: [.failure(anyNSError())])
        let sut = ImageDataLoaderWithFallbackComposite(primary: primary, fallback: fallback)
        
        do {
            _ = try await sut.loadImageData(for: anyURL())
            XCTFail("should not success")
        } catch {}
    }

}
