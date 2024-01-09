//
//  PhotoDetailPresentationAdapter.swift
//  PicsumApp
//
//  Created by Tsz-Lung on 09/01/2024.
//

import UIKit

final class PhotoDetailPresentationAdapter: PhotoDetailViewControllerDelegate {
    private(set) var task: Task<Void, Never>?
    
    private let photoURL: URL
    private let viewModel: PhotoDetailViewModel<UIImage>
    private let imageDataLoader: ImageDataLoader
    private let imageConverter: (Data) -> UIImage?
    
    init(photoURL: URL,
         viewModel: PhotoDetailViewModel<UIImage>,
         imageDataLoader: ImageDataLoader,
         imageConverter: @escaping (Data) -> UIImage?) {
        self.photoURL = photoURL
        self.viewModel = viewModel
        self.imageDataLoader = imageDataLoader
        self.imageConverter = imageConverter
    }
    
    func loadImageData() {
        viewModel.didStartLoading()
        task = Task { @MainActor in
            do {
                let data = try await imageDataLoader.loadImageData(for: photoURL)
                viewModel.didFinishLoading(with: imageConverter(data))
            } catch {
                viewModel.didFinishLoadingWithError()
            }
        }
    }
}
