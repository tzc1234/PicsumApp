//
//  PhotoGridComposer.swift
//  PicsumApp
//
//  Created by Tsz-Lung on 15/01/2024.
//

import SwiftUI

enum PhotoGridComposer {
    static func composeWith(photosLoader: PhotosLoader,
                            imageLoader: PhotoImageDataLoader) -> PhotoGridView {
        let viewModel = PhotoListViewModel()
        let paginatedPhotosLoaderAdapter = PaginatedPhotosLoaderAdapter(loader: photosLoader)
        let presentationAdapter = PhotoListPresentationAdapter(viewModel: viewModel, paginatedPhotos: {
            try await paginatedPhotosLoaderAdapter.makePaginatedPhotos()
        })
        
        let store = PhotoGridStore(model: viewModel, delegate: presentationAdapter)
        return PhotoGridView(store: store, gridItem: { photo in
            makePhotoGridItem(photo: photo, imageLoader: imageLoader).eraseToAnyView()
        })
    }
    
    private static func makePhotoGridItem(photo: Photo,
                                          imageLoader: PhotoImageDataLoader) -> PhotoGridItemContainer {
        let viewModel = PhotoImageViewModel<UIImage>()
        let adapter = PhotoImagePresentationAdapter(
            photoId: photo.id,
            viewModel: viewModel,
            imageLoader: imageLoader,
            imageConverter: UIImage.init)
        let store = PhotoGridItemStore(delegate: adapter)
        return PhotoGridItemContainer(store: store, author: photo.author)
    }
}
