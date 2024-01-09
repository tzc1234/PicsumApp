//
//  PhotoListComposer.swift
//  PicsumApp
//
//  Created by Tsz-Lung on 05/07/2023.
//

import UIKit

enum PhotoListComposer {
    static func composeWith(viewModel: PhotoListViewModel,
                            imageLoader: PhotoImageDataLoader,
                            selection: @escaping (Photo) -> Void) -> PhotoListViewController {
        let viewController = PhotoListViewController(viewModel: viewModel)
        
        viewModel.didLoad = { [weak viewController] photos in
            viewController?.display(cellControllers(
                from: photos, imageLoader: imageLoader, selection: selection))
        }
        
        viewModel.didLoadMore = { [weak viewController] photos in
            viewController?.displayMore(cellControllers(
                from: photos, imageLoader: imageLoader, selection: selection))
        }
        
        return viewController
    }
    
    private static func cellControllers(from photos: [Photo],
                                        imageLoader: PhotoImageDataLoader,
                                        selection: @escaping (Photo) -> Void) -> [PhotoListCellController] {
        photos.map { photo in
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
                selection: { selection(photo) })
        }
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
