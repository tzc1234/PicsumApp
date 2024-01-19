//
//  PhotoDetailContainerIntegrationTests.swift
//  PicsumAppTests
//
//  Created by Tsz-Lung on 19/01/2024.
//

import XCTest
import ViewInspector
@testable import PicsumApp

final class PhotoDetailContainerIntegrationTests: XCTestCase {
    func test_detailView_rendersPhotoDetailCorrectly() throws {
        let photo = makePhoto(author: "author0", webURL: URL(string: "https://web0-url.com")!)
        let (sut, _) = makeSUT(photo: photo, dataStubs: [anySuccessData()])
        
        try assertThat(sut, hasConfigureFor: photo)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(photo: Photo,
                         dataStubs: [PhotosLoaderSpy.DataResult] = [],
                         function: String = #function,
                         file: StaticString = #filePath,
                         line: UInt = #line) -> (sut: PhotoDetailContainer, loader: LoaderSpy) {
        let loader = LoaderSpy(dataStubs: dataStubs)
        let sut = PhotoDetailContainerComposer.composeWith(photo: photo)
        ViewHosting.host(view: sut, function: function)
        trackMemoryLeaks(for: loader, function: function, file: file, line: line)
        return (sut, loader)
    }
    
    private func trackMemoryLeaks(for instance: AnyObject,
                                  function: String = #function,
                                  file: StaticString = #file,
                                  line: UInt = #line) {
        addTeardownBlock { [weak instance] in
            ViewHosting.expel(function: function)
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                XCTAssertNil(
                    instance,
                    "Instance should have been deallocated. Potential memory leak.",
                    file: file,
                    line: line
                )
            }
        }
    }
    
    private func assertThat(_ sut: PhotoDetailContainer, 
                            hasConfigureFor photo: Photo,
                            file: StaticString = #filePath,
                            line: UInt = #line) throws {
        XCTAssertEqual(try sut.authorText(), photo.author, file: file, line: line)
        XCTAssertEqual(try sut.webURL(), photo.webURL, file: file, line: line)
    }
    
    private func anySuccessData() -> Result<Data, Error> {
        .success(anyData())
    }
    
    private class LoaderSpy: ImageDataLoader {
        typealias DataResult = Swift.Result<Data, Error>
        
        private(set) var dataStubs: [DataResult]
        private(set) var loggedURLs = [URL]()
        
        init(dataStubs: [DataResult]) {
            self.dataStubs = dataStubs
        }
        
        func loadImageData(for url: URL) async throws -> Data {
            loggedURLs.append(url)
            return try dataStubs.removeFirst().get()
        }
    }
}

extension PhotoDetailContainer {
    func authorText() throws -> String {
        try inspect()
            .find(viewWithAccessibilityIdentifier: "photo-detail-author")
            .text()
            .string()
    }
    
    func webURL() throws -> URL {
        try inspect()
            .find(viewWithAccessibilityIdentifier: "photo-detail-link")
            .link()
            .url()
    }
}
