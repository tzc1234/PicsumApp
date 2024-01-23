//
//  PhotoDetailPresentationAdapter.swift
//  PicsumApp
//
//  Created by Tsz-Lung on 09/01/2024.
//

import Foundation

final class PhotoDetailPresentationAdapter<Image>: ImageLoadingDelegate {
    private(set) var task: Task<Void, Never>?
    
    private let imageURL: URL
    private let viewModel: PhotoDetailViewModel<Image>
    private let imageDataLoader: ImageDataLoader
    private let imageConverter: (Data) -> Image?
    
    init(imageURL: URL,
         viewModel: PhotoDetailViewModel<Image>,
         imageDataLoader: ImageDataLoader,
         imageConverter: @escaping (Data) -> Image?) {
        self.imageURL = imageURL
        self.viewModel = viewModel
        self.imageDataLoader = imageDataLoader
        self.imageConverter = imageConverter
    }
    
    func loadImageData() {
        viewModel.didStartLoading()
        task = Task { @MainActor in
            do {
                let data = try await imageDataLoader.loadImageData(for: imageURL)
                viewModel.didFinishLoading(with: imageConverter(data))
            } catch {
                viewModel.didFinishLoadingWithError()
            }
        }
    }
}

private extension PhotoDetailViewModel {
    func didStartLoading() {
        onLoad?(true)
        shouldReload?(false)
    }
    
    func didFinishLoading(with image: Image?) {
        didLoad?(image)
        shouldReload?(false)
        onLoad?(false)
    }
    
    func didFinishLoadingWithError() {
        shouldReload?(true)
        onLoad?(false)
    }
}
