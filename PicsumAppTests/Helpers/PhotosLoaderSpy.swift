//
//  PhotosLoaderSpy.swift
//  PicsumAppTests
//
//  Created by Tsz-Lung on 03/07/2023.
//

import Foundation
@testable import PicsumApp

class PhotosLoaderSpy: PhotosLoader {
    typealias Result = Swift.Result<[Photo], Error>
    
    var beforeLoad: (@MainActor () -> Void)?
    private(set) var loggedPages = [Int]()
    
    private(set) var stubs: [Result]
    
    init(stubs: [Result]) {
        self.stubs = stubs
    }
    
    func load(page: Int) async throws -> [Photo] {
        await beforeLoad?()
        loggedPages.append(page)
        return try stubs.removeFirst().get()
    }
}
