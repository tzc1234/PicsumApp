//
//  PhotoDetailContainerComposer.swift
//  PicsumApp
//
//  Created by Tsz-Lung on 19/01/2024.
//

import SwiftUI

enum PhotoDetailContainerComposer {
    static func composeWith(photo: Photo, imageDataLoader: ImageDataLoader) -> PhotoDetailContainer {
        let viewModel = PhotoDetailViewModel<UIImage>(photo: photo)
        let adapter = PhotoDetailPresentationAdapter(
            imageURL: photo.url,
            viewModel: viewModel,
            imageDataLoader: imageDataLoader,
            imageConverter: UIImage.init)
        let store = PhotoDetailStore(viewModel: viewModel, delegate: adapter)
        return PhotoDetailContainer(store: store)
    }
}
