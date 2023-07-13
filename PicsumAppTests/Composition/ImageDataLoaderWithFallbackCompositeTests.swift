//
//  ImageDataLoaderWithFallbackCompositeTests.swift
//  PicsumAppTests
//
//  Created by Tsz-Lung on 13/07/2023.
//

import XCTest
@testable import PicsumApp

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
    
    func test_loadImageData_loadsDataOnLoadersForURL() async throws {
        let primary = ImageDataLoaderSpy(stubs: [.failure(anyNSError())])
        let fallback = ImageDataLoaderSpy(stubs: [.success(anyData())])
        let sut = ImageDataLoaderWithFallbackComposite(primary: primary, fallback: fallback)
        let url = anyURL()
        
        _ = try await sut.loadImageData(for: url)
        
        XCTAssertEqual(primary.loggedURLs, [url])
        XCTAssertEqual(fallback.loggedURLs, [url])
    }

}
