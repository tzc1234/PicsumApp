//
//  PhotoListComposer.swift
//  PicsumApp
//
//  Created by Tsz-Lung on 05/07/2023.
//

import UIKit

enum PhotoListComposer {
    static func composeWith(photosLoader: PhotosLoader,
                            imageLoader: PhotoImageDataLoader,
                            selection: @escaping (Photo) -> Void) -> PhotoListViewController {
        let viewModel = PhotoListViewModel()
        let paginatedPhotosLoaderAdapter = PaginatedPhotosLoaderAdapter(loader: photosLoader)
        let presentationAdapter = PhotoListPresentationAdapter(viewModel: viewModel, paginatedPhotos: {
            try await paginatedPhotosLoaderAdapter.makePaginatedPhotos()
        })
        let viewController = PhotoListViewController(viewModel: viewModel, delegate: presentationAdapter)
        viewController.title = PhotoListViewModel.title
        
        setupBindingsBetween(viewModel: viewModel, 
                             viewController: viewController,
                             withImageLoader: imageLoader, 
                             andSelection: selection)
        
        return viewController
    }
    
    private static func setupBindingsBetween(viewModel: PhotoListViewModel, 
                                             viewController: PhotoListViewController,
                                             withImageLoader imageLoader: PhotoImageDataLoader,
                                             andSelection selection: @escaping (Photo) -> Void) {
        viewModel.didLoad = { [weak viewController] photos in
            viewController?.display(cellControllers(
                from: photos, imageLoader: imageLoader, selection: selection))
        }
        
        viewModel.didLoadMore = { [weak viewController] photos in
            viewController?.displayMore(cellControllers(
                from: photos, imageLoader: imageLoader, selection: selection))
        }
    }
    
    private static func cellControllers(from photos: [Photo],
                                        imageLoader: PhotoImageDataLoader,
                                        selection: @escaping (Photo) -> Void) -> [PhotoListCellController] {
        photos.map { photo in
            PhotoViewComposer.composerWith(photo: photo, imageLoader: imageLoader, selection: { selection(photo) })
        }
    }
}
