//
//  PhotoViewComposer.swift
//  PicsumApp
//
//  Created by Tsz-Lung on 09/01/2024.
//

import UIKit

enum PhotoViewComposer {
    static func composerWith(photo: Photo,
                             imageLoader: PhotoImageDataLoader,
                             selection: @escaping () -> Void) -> PhotoListCellController {
        let viewModel = PhotoImageViewModel<UIImage>()
        let adapter = PhotoImagePresentationAdapter(
            photoId: photo.id,
            viewModel: viewModel,
            imageLoader: imageLoader,
            imageConverter: UIImage.init)
        return PhotoListCellController(
            author: photo.author,
            delegate: adapter,
            setupBindings: { vc in
                setupImageViewBindingsBetween(viewModel: viewModel, viewController: vc)
            },
            selection: selection)
    }
    
    private static func setupImageViewBindingsBetween(viewModel: PhotoImageViewModel<UIImage>,
                                                      viewController: PhotoListCellController) {
        viewModel.onLoadImage = { [weak viewController] isLoading in
            viewController?.cell?.imageContainerView.isShimmering = isLoading
        }
        
        viewModel.didLoadImage = { [weak viewController] image in
            viewController?.cell?.imageView.image = image
        }
    }
}
