//
//  PhotoDetailViewModel.swift
//  PicsumApp
//
//  Created by Tsz-Lung on 16/07/2023.
//

import Foundation

final class PhotoDetailViewModel<Image> {
    var onLoad: Observer<Bool>?
    var didLoad: Observer<Image?>?
    var shouldReload: Observer<Bool>?
    var author: String { photo.author }
    var webURL: URL { photo.webURL }
    var width: Int { photo.width }
    var height: Int { photo.height }
    
    private(set) var task: Task<Void, Never>?
    
    private let photo: Photo
    private let imageDataLoader: ImageDataLoader
    private let imageConverter: (Data) -> Image?
    
    init(photo: Photo, imageDataLoader: ImageDataLoader, imageConverter: @escaping (Data) -> Image?) {
        self.photo = photo
        self.imageDataLoader = imageDataLoader
        self.imageConverter = imageConverter
    }
    
    func loadImageData() {
        onLoad?(true)
        shouldReload?(false)
        
        task = Task { @MainActor in
            do {
                let data = try await imageDataLoader.loadImageData(for: photo.url)
                didLoad?(imageConverter(data))
                shouldReload?(false)
            } catch {
                shouldReload?(true)
            }

            onLoad?(false)
        }
    }
    
    static var title: String {
        "Photo"
    }
}
