//
//  PhotosLoaderSpyResultHelpers.swift
//  PicsumAppTests
//
//  Created by Tsz-Lung on 18/01/2024.
//

import XCTest

protocol PhotosLoaderSpyResultHelpersForTest: XCTestCase {}

extension PhotosLoaderSpyResultHelpersForTest {
    func emptySuccessPhotos() -> PhotosLoaderSpy.PhotosResult {
        .success([])
    }
    
    func anyFailure() -> PhotosLoaderSpy.PhotosResult {
        .failure(anyNSError())
    }
    
    func anyFailure() -> PhotosLoaderSpy.DataResult {
        .failure(anyNSError())
    }
    
    func anySuccessData() -> PhotosLoaderSpy.DataResult {
        .success(UIImage.makeData(withColor: .gray))
    }
}
