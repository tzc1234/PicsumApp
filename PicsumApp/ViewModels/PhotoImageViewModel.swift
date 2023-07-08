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
    
    private var image: Image?
    
    private let photo: Photo
    private let imageLoader: ImageDataLoader
    private let imageConverter: (Data) -> Image?
    
    init(photo: Photo, imageLoader: ImageDataLoader, imageConverter: @escaping (Data) -> Image?) {
        self.photo = photo
        self.imageLoader = imageLoader
        self.imageConverter = imageConverter
    }
    
    @MainActor
    func loadImage() async {
        onLoadImage?(true)
        justAfterOnLoadImage?()
        
        if let image {
            didLoadImage?(image)
        } else {
            let image = (try? await imageLoader.loadImageData(
                by: photo.id,
                width: UInt(photo.width),
                height: UInt(photo.height))).flatMap(imageConverter)
            self.image = image
            didLoadImage?(image)
        }
        
        onLoadImage?(false)
    }
}
