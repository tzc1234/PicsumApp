//
//  PhotoGridStore.swift
//  PicsumApp
//
//  Created by Tsz-Lung on 18/01/2024.
//

import SwiftUI

@Observable
final class PhotoGridStore {
    private(set) var isLoading = false
    private(set) var photos = [Photo]()
    private(set) var errorMessage: String?
    
    private var _showError = false
    var showError: Binding<Bool> {
        Binding(
            get: { self._showError },
            set: { showError in
                if !showError {
                    self.errorMessage = nil
                }
                self._showError = showError
            }
        )
    }
    
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
            self?._showError = errorMessage != nil
        }
    }
    
    func hideError() {
        showError.wrappedValue = false
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
