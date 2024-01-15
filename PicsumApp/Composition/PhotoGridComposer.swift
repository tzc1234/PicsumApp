//
//  PhotoGridComposer.swift
//  PicsumApp
//
//  Created by Tsz-Lung on 15/01/2024.
//

import SwiftUI

enum PhotoGridComposer {
    static func composeWith(photosLoader: PhotosLoader) -> PhotoGridView {
        let viewModel = PhotoListViewModel()
        let paginatedPhotosLoaderAdapter = PaginatedPhotosLoaderAdapter(loader: photosLoader)
        let presentationAdapter = PhotoListPresentationAdapter(viewModel: viewModel, paginatedPhotos: {
            try await paginatedPhotosLoaderAdapter.makePaginatedPhotos()
        })
        
        return PhotoGridView(delegate: presentationAdapter)
    }
}
