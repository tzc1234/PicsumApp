//
//  PhotoListComposer.swift
//  PicsumApp
//
//  Created by Tsz-Lung on 05/07/2023.
//

import UIKit

enum PhotoListComposer {
    static func composeWith(viewModel: PhotoListViewModel,
                            imageLoader: PhotoImageDataLoader) -> PhotoListViewController {
        let viewController = PhotoListViewController(viewModel: viewModel)
        
        viewModel.didLoad = { [weak viewController] photos in
            viewController?.set(convert(from: photos, imageLoader: imageLoader))
        }
        
        viewModel.didLoadMore = { [weak viewController] photos in
            viewController?.append(convert(from: photos, imageLoader: imageLoader))
        }
        
        return viewController
    }
    
    private static func convert(from photos: [Photo],
                        imageLoader: PhotoImageDataLoader) -> [PhotoListCellController] {
        photos.map { photo in
            let viewModel = PhotoImageViewModel(
                photo: photo,
                imageLoader: imageLoader,
                imageConverter: UIImage.init)
            return PhotoListCellController(viewModel: viewModel)
        }
    }
}
