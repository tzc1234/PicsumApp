//
//  PhotoGridComposer.swift
//  PicsumApp
//
//  Created by Tsz-Lung on 15/01/2024.
//

import SwiftUI

enum PhotoGridComposer {
    private typealias PhotoID = String
    
    static func composeWith(photosLoader: PhotosLoader,
                            imageLoader: PhotoImageDataLoader) -> PhotoGridView {
        let viewModel = PhotoListViewModel()
        let paginatedPhotosLoaderAdapter = PaginatedPhotosLoaderAdapter(loader: photosLoader)
        let presentationAdapter = PhotoListPresentationAdapter(viewModel: viewModel, paginatedPhotos: {
            try await paginatedPhotosLoaderAdapter.makePaginatedPhotos()
        })
        
        let store = PhotoGridStore(viewModel: viewModel, delegate: presentationAdapter)
        var containers = [PhotoID: PhotoGridItemContainer]()
        return PhotoGridView(store: store, gridItem: { photo in
            guard let container = containers[photo.id] else {
                let newContainer = makeGridItemContainer(photo: photo, imageLoader: imageLoader)
                containers[photo.id] = newContainer
                return newContainer.eraseToAnyView()
            }
            
            return container.eraseToAnyView()
        })
    }
    
    private static func makeGridItemContainer(photo: Photo,
                                              imageLoader: PhotoImageDataLoader) -> PhotoGridItemContainer {
        let viewModel = PhotoImageViewModel<UIImage>()
        let adapter = PhotoImagePresentationAdapter(
            photoId: photo.id,
            viewModel: viewModel,
            imageLoader: imageLoader,
            imageConverter: UIImage.init)
        let store = PhotoGridItemStore(viewModel: viewModel, delegate: adapter)
        return PhotoGridItemContainer(store: store, author: photo.author)
    }
}
