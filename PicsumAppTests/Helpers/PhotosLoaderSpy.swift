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
    private(set) var loggedURLs = [URL]()
    private(set) var photoStubs: [PhotosResult]
    
    init(photoStubs: [PhotosResult], dataStubs: [DataResult] = []) {
        self.photoStubs = photoStubs
        self.dataStubs = dataStubs
    }
    
    struct CannotFindFirstPhotoStub: Error {}
    
    @MainActor
    func load(for url: URL) async throws -> [Photo] {
        beforeLoad?()
        loggedURLs.append(url)
        
        guard !photoStubs.isEmpty else {
            throw CannotFindFirstPhotoStub()
        }
        
        return try photoStubs.removeFirst().get()
    }
    
    // MARK: - PhotoImageDataLoader
    
    typealias DataResult = Swift.Result<Data, Error>
    
    private(set) var dataStubs: [DataResult]
    private(set) var loggedPhotoIDs = [String]()
    var loggedPhotoIDSet: Set<String> { Set(loggedPhotoIDs) }
    
    struct CannotFindFirstImageDataStub: Error {}
    
    @MainActor
    func loadImageData(by id: String, width: Int, height: Int) async throws -> Data {
        loggedPhotoIDs.append(id)
        
        guard !dataStubs.isEmpty else {
            throw CannotFindFirstImageDataStub()
        }
        
        return try dataStubs.removeFirst().get()
    }
}
