//
//  PhotoDetailStore.swift
//  PicsumApp
//
//  Created by Tsz-Lung on 19/01/2024.
//

import Foundation

@Observable
final class PhotoDetailStore<Image> {
    private(set) var image: Image?
    private(set) var isLoading = false
    private(set) var shouldReload = false
    
    var photoDetail: PhotoDetail {
        viewModel.photoDetail
    }
    
    private let viewModel: PhotoDetailViewModel<Image>
    let delegate: ImageLoadingDelegate
    
    init(viewModel: PhotoDetailViewModel<Image>, delegate: ImageLoadingDelegate) {
        self.viewModel = viewModel
        self.delegate = delegate
        self.setupBindings()
        self.loadImage()
    }
    
    private func setupBindings() {
        viewModel.didLoad = { [weak self] image in
            self?.image = image
        }
        
        viewModel.onLoad = { [weak self] isLoading in
            self?.isLoading = isLoading
        }
        
        viewModel.shouldReload = { [weak self] shouldReload in
            self?.shouldReload = shouldReload
        }
    }
    
    func loadImage() {
        delegate.loadImageData()
    }
}
