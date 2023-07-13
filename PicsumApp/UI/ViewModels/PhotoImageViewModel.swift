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
    
    private let photo: Photo
    private let imageLoader: PhotoImageDataLoader
    private let imageConverter: (Data) -> Image?
    
    init(photo: Photo, imageLoader: PhotoImageDataLoader, imageConverter: @escaping (Data) -> Image?) {
        self.photo = photo
        self.imageLoader = imageLoader
        self.imageConverter = imageConverter
    }
    
    @MainActor
    func loadImage() async {
        onLoadImage?(true)
        justAfterOnLoadImage?()
        
        let image = (try? await imageLoader.loadImageData(
            by: photo.id,
            width: Self.photoDimension,
            height: Self.photoDimension)).flatMap(imageConverter)
        didLoadImage?(image)
        
        onLoadImage?(false)
    }
    
    private static var photoDimension: Int { 500 }
}
