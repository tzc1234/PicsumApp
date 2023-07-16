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
        let viewModel = PhotoDetailViewModel(
            photo: photo,
            imageDataLoader: imageDataLoader,
            imageConverter: UIImage.init)
        return PhotoDetailViewController(viewModel: viewModel, urlHandler: urlHandler)
    }
}
