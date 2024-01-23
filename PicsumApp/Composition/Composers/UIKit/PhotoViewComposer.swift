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
            viewModel: viewModel,
            delegate: adapter,
            selection: selection)
    }
}
