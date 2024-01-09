//
//  PhotoImagePresentationAdapter.swift
//  PicsumApp
//
//  Created by Tsz-Lung on 09/01/2024.
//

import UIKit

final class PhotoImagePresentationAdapter: PhotoListCellControllerDelegate {
    private let photoDimension = 600
    private(set) var task: Task<Void, Never>?
    
    private let photoId: String
    private let viewModel: PhotoImageViewModel<UIImage>
    private let imageLoader: PhotoImageDataLoader
    private let imageConverter: (Data) -> UIImage?
    
    init(photoId: String,
         viewModel: PhotoImageViewModel<UIImage>,
         imageLoader: PhotoImageDataLoader,
         imageConverter: @escaping (Data) -> UIImage?) {
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
