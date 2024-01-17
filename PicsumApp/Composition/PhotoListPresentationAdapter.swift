//
//  PhotoListPresentationAdapter.swift
//  PicsumApp
//
//  Created by Tsz-Lung on 09/01/2024.
//

import Foundation

final class PhotoListPresentationAdapter: PhotoListViewControllerDelegate {
    typealias PaginatedPhotos = () async throws -> Paginated<Photo>
    
    private(set) var loadPhotosTask: Task<Void, Never>?
    private(set) var loadMorePhotosTask: Task<Void, Never>?
    private var loadMore: PaginatedPhotos?
    private var isLoadingMore = false
    
    private let viewModel: PhotoListViewModel
    private let firstPaginatedPhotos: PaginatedPhotos
    
    init(viewModel: PhotoListViewModel, paginatedPhotos: @escaping PaginatedPhotos) {
        self.viewModel = viewModel
        self.firstPaginatedPhotos = paginatedPhotos
    }
    
    func loadPhotos() {
        viewModel.didStartLoading()
        
        loadPhotosTask?.cancel()
        loadPhotosTask = Task { @MainActor [weak self] in
            guard let self, !Task.isCancelled else { return }
            
            do {
                let paginated = try await firstPaginatedPhotos()
                loadMore = paginated.loadMore
                
                viewModel.didFinishLoading(with: paginated.items)
            } catch {
                viewModel.didFinishLoadingWithError()
            }
        }
    }
    
    func loadMorePhotos() {
        guard !isLoadingMore, let loadMore else { return }
        
        isLoadingMore = true
        loadMorePhotosTask = Task { @MainActor [weak self] in
            guard let self, !Task.isCancelled else { return }
            
            do {
                let paginated = try await loadMore()
                self.loadMore = paginated.loadMore
                
                viewModel.didFinishLoadingMore(with: paginated.items)
            } catch {
                viewModel.didFinishLoadingMoreWithError()
            }
            
            isLoadingMore = false
        }
    }
}

extension PhotoListViewModel {
    func didStartLoading() {
        onLoad?(true)
    }
    
    func didFinishLoading(with photos: [Photo]) {
        didLoad?(photos)
        onError?(nil)
        onLoad?(false)
    }
    
    func didFinishLoadingWithError() {
        onError?(Self.errorMessage)
        onLoad?(false)
    }
    
    func didFinishLoadingMore(with photos: [Photo]) {
        didLoadMore?(photos)
        onError?(nil)
    }
    
    func didFinishLoadingMoreWithError() {
        onError?(Self.errorMessage)
    }
}
