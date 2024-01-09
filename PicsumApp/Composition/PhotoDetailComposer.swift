//
//  PhotoDetailComposer.swift
//  PicsumApp
//
//  Created by Tsz-Lung on 16/07/2023.
//

import UIKit

enum PhotoDetailComposer {
    static func composeWith(photo: Photo,
                            imageDataLoader: ImageDataLoader,
                            urlHandler: @escaping (URL) -> Void = { url in
                                UIApplication.shared.open(url)
                            }) -> PhotoDetailViewController {
        let viewModel = PhotoDetailViewModel<UIImage>(photo: photo)
        let adapter = PhotoDetailPresentationAdapter(
            photoURL: photo.url,
            viewModel: viewModel,
            imageDataLoader: imageDataLoader,
            imageConverter: UIImage.init)
        let controller = PhotoDetailViewController(
            photoDetail: viewModel.photoDetail,
            urlHandler: urlHandler,
            delegate: adapter)
        controller.title = PhotoDetailViewModel<UIImage>.title
        
        setupBindingsBetween(viewModel: viewModel, viewController: controller)
        
        return controller
    }
    
    private static func setupBindingsBetween(viewModel: PhotoDetailViewModel<UIImage>,
                                             viewController: PhotoDetailViewController) {
        viewModel.onLoad = { [weak viewController] isLoading in
            viewController?.imageContainerView.isShimmering = isLoading
        }
        
        viewModel.didLoad = { [weak viewController] image in
            viewController?.imageView.image = image
        }
        
        viewModel.shouldReload = { [weak viewController] shouldReload in
            viewController?.reloadButton.isHidden = !shouldReload
        }
    }
}
