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
            imageURL: photo.url,
            viewModel: viewModel,
            imageDataLoader: imageDataLoader,
            imageConverter: UIImage.init)
        let controller = PhotoDetailViewController(viewModel: viewModel, urlHandler: urlHandler, delegate: adapter)
        controller.title = PhotoDetailViewModel<UIImage>.title
        
        return controller
    }
}
