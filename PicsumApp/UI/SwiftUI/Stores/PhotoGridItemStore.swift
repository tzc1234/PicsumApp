//
//  PhotoGridItemStore.swift
//  PicsumApp
//
//  Created by Tsz-Lung on 18/01/2024.
//

import Foundation

@Observable
final class PhotoGridItemStore<Image> {
    private(set) var image: Image?
    private(set) var isLoading = false
    
    private let viewModel: PhotoImageViewModel<Image>
    let delegate: PhotoListCellControllerDelegate
    
    init(viewModel: PhotoImageViewModel<Image>, delegate: PhotoListCellControllerDelegate) {
        self.viewModel = viewModel
        self.delegate = delegate
        self.setupBindings()
        self.loadImage()
    }
    
    private func setupBindings() {
        viewModel.didLoadImage = { [weak self] image in
            self?.image = image
        }
        
        viewModel.onLoadImage = { [weak self] isLoading in
            self?.isLoading = isLoading
        }
    }
    
    func loadImage() {
        delegate.loadImage()
    }
    
    func cancelLoadImage() {
        delegate.cancelLoad()
    }
}
