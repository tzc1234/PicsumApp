//
//  PhotoGridComposer.swift
//  PicsumApp
//
//  Created by Tsz-Lung on 15/01/2024.
//

import SwiftUI

enum PhotoGridComposer {
    private typealias PhotoID = String
    
    static func makeGridStore(photosLoader: PhotosLoader) -> PhotoGridStore {
        let viewModel = PhotoListViewModel()
        let paginatedPhotosLoaderAdapter = PaginatedPhotosLoaderAdapter(loader: photosLoader)
        let presentationAdapter = PhotoListPresentationAdapter(viewModel: viewModel, paginatedPhotos: {
            try await paginatedPhotosLoaderAdapter.makePaginatedPhotos()
        })
        return PhotoGridStore(viewModel: viewModel, delegate: presentationAdapter)
    }
    
    static func makePhotoGridView<NextView>(store: PhotoGridStore,
                                            imageLoader: PhotoImageDataLoader,
                                            nextView: @escaping (Photo) -> NextView)
    -> PhotoGridView<PhotoGridItemContainer, NextView> {
        var gridItemStores = [PhotoID: PhotoGridItemStore<UIImage>]()
        return PhotoGridView(
            store: store,
            gridItem: { photo in
                let store = if let cachedStore = gridItemStores[photo.id] {
                    cachedStore
                } else {
                    makeGridItemStore(photoId: photo.id, imageLoader: imageLoader)
                }
                
                gridItemStores[photo.id] = store
                
                return PhotoGridItemContainer(store: store, author: photo.author)
            },
            onGridItemDisappear: { photo in
                gridItemStores[photo.id] = nil
            },
            nextView: nextView
        )
    }
    
    private static func makeGridItemStore(photoId: PhotoID,
                                          imageLoader: PhotoImageDataLoader) -> PhotoGridItemStore<UIImage> {
        let viewModel = PhotoImageViewModel<UIImage>()
        let adapter = PhotoImagePresentationAdapter(
            photoId: photoId,
            viewModel: viewModel,
            imageLoader: imageLoader,
            imageConverter: UIImage.init)
        return PhotoGridItemStore(viewModel: viewModel, delegate: adapter)
    }
}
