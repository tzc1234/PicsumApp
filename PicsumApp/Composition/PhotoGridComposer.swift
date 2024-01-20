//
//  PhotoGridComposer.swift
//  PicsumApp
//
//  Created by Tsz-Lung on 15/01/2024.
//

import SwiftUI

enum PhotoGridComposer {
    private typealias PhotoID = String
    
    static func composeWith<NextView>(photosLoader: PhotosLoader,
                                      imageLoader: PhotoImageDataLoader,
                                      nextView: @escaping (Photo) -> NextView) 
    -> PhotoGridView<PhotoGridItemContainer, NextView> {
        let viewModel = PhotoListViewModel()
        let paginatedPhotosLoaderAdapter = PaginatedPhotosLoaderAdapter(loader: photosLoader)
        let presentationAdapter = PhotoListPresentationAdapter(viewModel: viewModel, paginatedPhotos: {
            try await paginatedPhotosLoaderAdapter.makePaginatedPhotos()
        })
        
        let store = PhotoGridStore(viewModel: viewModel, delegate: presentationAdapter)
        var gridItemStores = [PhotoID: PhotoGridItemStore<UIImage>]()
        return PhotoGridView(
            store: store,
            gridItem: { photo in
                let store = if let cachedStore = gridItemStores[photo.id] {
                    cachedStore
                } else {
                    makeGridItemStore(photo: photo, imageLoader: imageLoader)
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
    
    private static func makeGridItemStore(photo: Photo,
                                          imageLoader: PhotoImageDataLoader) -> PhotoGridItemStore<UIImage> {
        let viewModel = PhotoImageViewModel<UIImage>()
        let adapter = PhotoImagePresentationAdapter(
            photoId: photo.id,
            viewModel: viewModel,
            imageLoader: imageLoader,
            imageConverter: UIImage.init)
        return PhotoGridItemStore(viewModel: viewModel, delegate: adapter)
    }
}
