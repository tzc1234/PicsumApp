//
//  PhotosLoaderSpy.swift
//  PicsumAppTests
//
//  Created by Tsz-Lung on 03/07/2023.
//

import Foundation
@testable import PicsumApp

class PhotosLoaderSpy: PhotosLoader, PhotoImageDataLoader {
    // MARK: - PhotosLoader
    
    typealias PhotosResult = Swift.Result<[Photo], Error>
    
    var beforeLoad: (() -> Void)?
    private(set) var loggedPages = [Int]()
    private(set) var photoStubs: [PhotosResult]
    
    init(photoStubs: [PhotosResult], dataStubs: [DataResult]) {
        self.photoStubs = photoStubs
        self.dataStubs = dataStubs
    }
    
    @MainActor
    func load(page: Int) async throws -> [Photo] {
        beforeLoad?()
        loggedPages.append(page)
        return try photoStubs.removeFirst().get()
    }
    
    // MARK: - PhotoImageDataLoader
    typealias DataResult = Swift.Result<Data, Error>
    
    private(set) var dataStubs: [DataResult]
    private(set) var loggedPhotoIDs = [String]()
    
    @MainActor
    func loadImageData(by id: String, width: Int, height: Int) async throws -> Data {
        loggedPhotoIDs.append(id)
        return try dataStubs.removeFirst().get()
    }
}