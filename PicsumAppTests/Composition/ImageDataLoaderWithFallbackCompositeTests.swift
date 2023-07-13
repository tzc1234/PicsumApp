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
        try await primary.loadImageData(for: url)
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

}
