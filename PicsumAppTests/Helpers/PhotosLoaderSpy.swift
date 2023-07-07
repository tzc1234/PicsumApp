//
//  PhotosLoaderSpy.swift
//  PicsumAppTests
//
//  Created by Tsz-Lung on 03/07/2023.
//

import Foundation
@testable import PicsumApp

class PhotosLoaderSpy: PhotosLoader, ImageDataLoader {
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
    
    // MARK: - ImageDataLoader
    typealias DataResult = Swift.Result<Data, Error>
    
    private(set) var dataStubs: [DataResult]
    private(set) var loggedPhotoIDs = [String]()
    
    @MainActor
    func loadImageData(by id: String, width: UInt, height: UInt) async throws -> Data {
        loggedPhotoIDs.append(id)
        guard !dataStubs.isEmpty else { throw anyNSError() }
        let data = try dataStubs.removeFirst().get()
        return data
    }
}
