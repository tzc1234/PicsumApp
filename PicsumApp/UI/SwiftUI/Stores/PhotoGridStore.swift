//
//  PhotoGridStore.swift
//  PicsumApp
//
//  Created by Tsz-Lung on 18/01/2024.
//

import Foundation

@Observable
final class PhotoGridStore {
    private(set) var isLoading = false
    private(set) var photos = [Photo]()
    private(set) var errorMessage: String?
    var selectedPhoto: Photo?
    
    private let viewModel: PhotoListViewModel
    let delegate: PhotosLoadingDelegate
    
    init(viewModel: PhotoListViewModel, delegate: PhotosLoadingDelegate) {
        self.viewModel = viewModel
        self.delegate = delegate
        self.setupBindings()
    }
    
    private func setupBindings() {
        viewModel.onLoad = { [weak self] isLoading in
            self?.isLoading = isLoading
        }
        
        viewModel.didLoad = { [weak self] photos in
            self?.photos = photos
        }
        
        viewModel.didLoadMore = { [weak self] photos in
            self?.photos += photos
        }
        
        viewModel.onError = { [weak self] errorMessage in
            self?.errorMessage = errorMessage
        }
    }
    
    func clearErrorMessage() {
        errorMessage = nil
    }
    
    func loadPhotos() {
        isLoading = true
        cancelAllPendingPhotosTask()
        delegate.loadPhotos()
    }
    
    private func cancelAllPendingPhotosTask() {
        delegate.loadPhotosTask?.cancel()
        delegate.loadMorePhotosTask?.cancel()
    }
    
    func asyncLoadPhotos() async {
        loadPhotos()
        await trackFinishLoading()
    }
    
    private func trackFinishLoading() async {
        guard isLoading else { return }
        
        try? await Task.sleep(for: .seconds(0.1))
        await trackFinishLoading()
    }
    
    func loadMorePhotos() {
        delegate.loadMorePhotos()
    }
    
    static var title: String {
        PhotoListViewModel.title
    }
    
    static var errorTitle: String {
        PhotoListViewModel.errorTitle
    }
}
