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
    
    typealias Result = Swift.Result<[Photo], Error>
    
    var beforeLoad: (@MainActor () -> Void)?
    private(set) var loggedPages = [Int]()
    private(set) var photoStubs: [Result]
    
    init(photoStubs: [Result], dataStubs: [Data]) {
        self.photoStubs = photoStubs
        self.dataStubs = dataStubs
    }
    
    func load(page: Int) async throws -> [Photo] {
        await beforeLoad?()
        loggedPages.append(page)
        return try photoStubs.removeFirst().get()
    }
    
    // MARK: - ImageDataLoader
    
    private(set) var dataStubs: [Data]
    private(set) var loadedImageURLs = [URL]()
    
    func loadImageData(from url: URL) async throws -> Data {
        loadedImageURLs.append(url)
        return Data()
    }
}
