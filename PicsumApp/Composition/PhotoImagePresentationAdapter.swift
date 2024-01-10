//
//  PhotoImagePresentationAdapter.swift
//  PicsumApp
//
//  Created by Tsz-Lung on 09/01/2024.
//

import Foundation

final class PhotoImagePresentationAdapter<Image>: PhotoListCellControllerDelegate {
    private let photoDimension = 600
    private(set) var task: Task<Void, Never>?
    
    private let photoId: String
    private let viewModel: PhotoImageViewModel<Image>
    private let imageLoader: PhotoImageDataLoader
    private let imageConverter: (Data) -> Image?
    
    init(photoId: String,
         viewModel: PhotoImageViewModel<Image>,
         imageLoader: PhotoImageDataLoader,
         imageConverter: @escaping (Data) -> Image?) {
        self.photoId = photoId
        self.viewModel = viewModel
        self.imageLoader = imageLoader
        self.imageConverter = imageConverter
    }
    
    func loadImage() {
        viewModel.didStartLoading()
        
        task?.cancel()
        task = Task { @MainActor [weak self] in
            guard let self, !Task.isCancelled else { return }
            
            let data = try? await imageLoader.loadImageData(by: photoId, width: photoDimension, height: photoDimension)
            
            if !Task.isCancelled {
                let image = data.flatMap(imageConverter)
                viewModel.didFinishLoading(with: image)
            }
        }
    }
    
    func cancelLoad() {
        task?.cancel()
        task = nil
    }
}

private extension PhotoImageViewModel {
    func didStartLoading() {
        onLoadImage?(true)
    }
    
    func didFinishLoading(with image: Image?) {
        didLoadImage?(image)
        onLoadImage?(false)
    }
}
