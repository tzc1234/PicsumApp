//
//  ImageDataLoaderSpy.swift
//  PicsumAppTests
//
//  Created by Tsz-Lung on 13/07/2023.
//

import Foundation
@testable import PicsumApp

class ImageDataLoaderSpy: ImageDataLoader {
    typealias Stub = Result<Data, Error>
    
    private(set) var loggedURLs = [URL]()
    private var stubs: [Stub]
    
    init(stubs: [Stub]) {
        self.stubs = stubs
    }
    
    func loadImageData(for url: URL) async throws -> Data {
        loggedURLs.append(url)
        return try stubs.removeFirst().get()
    }
}
