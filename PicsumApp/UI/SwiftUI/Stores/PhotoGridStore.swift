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
    let delegate: PhotoListViewControllerDelegate
    
    init(viewModel: PhotoListViewModel, delegate: PhotoListViewControllerDelegate) {
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
    
    @MainActor
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
        await loadPhotos()
        await trackFinishLoading()
    }
    
    private func trackFinishLoading() async {
        guard isLoading else { return }
        
        try? await Task.sleep(for: .seconds(0.1))
        await trackFinishLoading()
    }
    
    @MainActor
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
