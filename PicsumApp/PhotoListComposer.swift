//
//  PhotoListComposer.swift
//  PicsumApp
//
//  Created by Tsz-Lung on 05/07/2023.
//

import UIKit

enum PhotoListComposer {
    static func composeWith(viewModel: PhotoListViewModel, imageLoader: ImageDataLoader) -> PhotoListViewController {
        let viewController = PhotoListViewController(viewModel: viewModel)
        
        viewModel.didLoad = { [weak viewController] photos in
            viewController?.cellControllers = photos.map { photo in
                let viewModel = PhotoImageViewModel(photo: photo, imageLoader: imageLoader, imageConverter: UIImage.init)
                return PhotoListCellController(viewModel: viewModel)
            }
        }
        
        return viewController
    }
}
