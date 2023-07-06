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
        
        let image = (try? await imageLoader.loadImageData(from: photo.url)).flatMap(imageConverter)
        didLoadImage?(image)
        
        onLoadImage?(false)
    }
}
