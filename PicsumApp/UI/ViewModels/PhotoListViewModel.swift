//
//  PhotoListViewModel.swift
//  PicsumApp
//
//  Created by Tsz-Lung on 03/07/2023.
//

import Foundation

typealias Observer<T> = (T) -> Void

final class PhotoListViewModel {
    typealias PaginatedPhotos = () async throws -> Paginated<Photo>
    
    var onLoad: Observer<Bool>?
    var onError: Observer<String?>?
    var didLoad: Observer<[Photo]>?
    var didLoadMore: Observer<[Photo]>?
    
    private var isLoadingMore = false
    private(set) var loadPhotosTask: Task<Void, Never>?
    private(set) var loadMorePhotosTask: Task<Void, Never>?
    private var loadMore: PaginatedPhotos?
    
    private let firstPaginatedPhotos: PaginatedPhotos
    
    init(paginatedPhotos: @escaping PaginatedPhotos) {
        self.firstPaginatedPhotos = paginatedPhotos
    }
    
    func loadPhotos() {
        onLoad?(true)
        
        loadPhotosTask?.cancel()
        loadPhotosTask = loadPhotosTask(action: { [weak self] in
            guard let self else { return }
            
            let paginated = try await firstPaginatedPhotos()
            loadMore = paginated.loadMore
            
            didLoad?(paginated.items)
        }, completion: { [weak self] in
            self?.onLoad?(false)
        })
    }
    
    func loadMorePhotos() {
        guard !isLoadingMore, let loadMore else { return }
        
        isLoadingMore = true
        loadMorePhotosTask = loadPhotosTask(action: { [weak self] in
            guard let self else { return }
            
            let paginated = try await loadMore()
            self.loadMore = paginated.loadMore
            
            didLoadMore?(paginated.items)
        }, completion: { [weak self] in
            self?.isLoadingMore = false
        })
    }
    
    private func loadPhotosTask(action: @escaping () async throws -> Void,
                                completion: @escaping () -> Void) -> Task<Void, Never> {
        Task { @MainActor in
            guard !Task.isCancelled else { return }
            
            do {
                try await action()
                onError?(nil)
            } catch {
                onError?(Self.errorMessage)
            }
            
            completion()
        }
    }
    
    static var errorMessage: String {
        "Error occurred, please try again."
    }
    
    static var title: String {
        "Photos"
    }
}
