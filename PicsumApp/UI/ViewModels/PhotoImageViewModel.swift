//
//  PhotoImageViewModel.swift
//  PicsumApp
//
//  Created by Tsz-Lung on 06/07/2023.
//

import Foundation

final class PhotoImageViewModel<Image> {
    var onLoadImage: Observer<Bool>?
    var didLoadImage: Observer<Image?>?
    var author: String { photo.author }
    
    /// For testing purpose, cannot find a better way to observe the loading state just after loading for async/await.
    var justAfterOnLoadImage: (() -> Void)?
    private(set) var imageDataTask: Task<Void, Never>?
    
    private let photo: Photo
    private let imageLoader: PhotoImageDataLoader
    private let imageConverter: (Data) -> Image?
    
    init(photo: Photo, imageLoader: PhotoImageDataLoader, imageConverter: @escaping (Data) -> Image?) {
        self.photo = photo
        self.imageLoader = imageLoader
        self.imageConverter = imageConverter
    }
    
    func loadImage() {
        imageDataTask = Task { @MainActor [weak self] in
            guard let self else { return }
            
            self.onLoadImage?(true)
            self.justAfterOnLoadImage?()
            
            let image = (try? await self.imageLoader.loadImageData(
                by: self.photo.id,
                width: Self.photoDimension,
                height: Self.photoDimension)).flatMap(self.imageConverter)
            self.didLoadImage?(image)
            
            self.onLoadImage?(false)
        }
    }
    
    func cancelLoad() {
        imageDataTask?.cancel()
        imageDataTask = nil
    }
    
    private static var photoDimension: Int { 600 }
}
