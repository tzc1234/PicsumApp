//
//  PhotoListViewModelTests.swift
//  PicsumAppTests
//
//  Created by Tsz-Lung on 03/07/2023.
//

import XCTest
@testable import PicsumApp

final class PhotoListViewModelTests: XCTestCase {
    func test_didStartLoading_deliversOnLoad() {
        let sut = makeSUT()
        
        assertWith(loadings: [true], from: sut, when: {
            sut.didStartLoading()
        })
    }
    
    func test_didFinishLoadingWithPhotos_deliversPhotos() {
        let sut = makeSUT()
        let photoSet = [makePhoto(id: "0"), makePhoto(id: "1")]
        
        assertWith(loadings: [false], errors: [nil], photos: [photoSet], from: sut, when: {
            sut.didFinishLoading(with: photoSet)
        })
    }
    
    func test_didFinishLoadingWithError_deliversError() {
        let sut = makeSUT()
        
        assertWith(loadings: [false], errors: [errorMessage], from: sut, when: {
            sut.didFinishLoadingWithError()
        })
    }
    
    func test_didFinishLoadingMoreWithPhotos_deliversPhotos() {
        let sut = makeSUT()
        let photoSet = [makePhoto(id: "0"), makePhoto(id: "1")]
        
        assertWith(errors: [nil], morePhotos: [photoSet], from: sut, when: {
            sut.didFinishLoadingMore(with: photoSet)
        })
    }
    
    func test_didFinishLoadingMoreWithError_deliversError() {
        let sut = makeSUT()
        
        assertWith(errors: [errorMessage], from: sut, when: {
            sut.didFinishLoadingMoreWithError()
        })
    }
    
    // MARK: - Helpers
    
    private func makeSUT() -> PhotoListViewModel {
        .init()
    }
    
    private func assertWith(loadings: [Bool]? = nil,
                            errors: [String?]? = nil,
                            photos: [[Photo]]? = nil,
                            morePhotos: [[Photo]]? = nil,
                            from sut: PhotoListViewModel,
                            when action: () -> Void,
                            file: StaticString = #filePath,
                            line: UInt = #line) {
        let received = received(from: sut, when: action)
        
        if let loadings {
            XCTAssertEqual(received.loadings, loadings, file: file, line: line)
        }
        
        if let errors {
            XCTAssertEqual(received.errors, errors, file: file, line: line)
        }
        
        if let photos {
            XCTAssertEqual(received.photos, photos, file: file, line: line)
        }
        
        if let morePhotos {
            XCTAssertEqual(received.morePhotos, morePhotos, file: file, line: line)
        }
    }
    
    private func received(from sut: PhotoListViewModel,
                          when action: () -> Void)
    -> (loadings: [Bool], errors: [String?], photos: [[Photo]], morePhotos: [[Photo]]) {
        var loadings = [Bool]()
        sut.onLoad = { loadings.append($0) }
        
        var errors = [String?]()
        sut.onError = { errors.append($0) }
        
        var photos = [[Photo]]()
        sut.didLoad = { photos.append($0) }
        
        var morePhotos = [[Photo]]()
        sut.didLoadMore = { morePhotos.append($0) }
        
        action()
        
        return (loadings, errors, photos, morePhotos)
    }
    
    private var errorMessage: String {
        PhotoListViewModel.errorMessage
    }
}
