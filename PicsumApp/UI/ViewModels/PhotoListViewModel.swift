//
//  PhotoListViewModel.swift
//  PicsumApp
//
//  Created by Tsz-Lung on 03/07/2023.
//

import Foundation

typealias Observer<T> = (T) -> Void

final class PhotoListViewModel {
    var onLoad: Observer<Bool>?
    var onError: Observer<String?>?
    var didLoad: Observer<[Photo]>?
    var didLoadMore: Observer<[Photo]>?
    
    private var isLoadingMore = false
    private(set) var loadPhotosTask: Task<Void, Never>?
    private(set) var loadMorePhotosTask: Task<Void, Never>?
    private var loadMore: Paginated<Photo>.LoadMore?
    
    private let loader: PhotosLoader
    
    init(loader: PhotosLoader) {
        self.loader = loader
    }
    
    func loadPhotos() {
        onLoad?(true)
        
        loadPhotosTask?.cancel()
        loadPhotosTask = loadPhotosTask(action: { [weak self] in
            guard let self else { return }
            
            let firstLoad = makeFirstPaginatedPhotos()
            let paginated = try await firstLoad()
            loadMore = paginated.loadMore
            
            didLoad?(paginated.items)
        }, completion: { [weak self] in
            self?.onLoad?(false)
        })
    }
    
    private func makeFirstPaginatedPhotos(page: Int = 1) -> () async throws -> Paginated<Photo> {
        { [weak self] in
            guard let self else { return .empty }
            
            let morePhotos = try await loader.load(page: page)
            let canLoadMore = !morePhotos.isEmpty
            return Paginated(
                items: morePhotos,
                loadMore: canLoadMore ? makeFirstPaginatedPhotos(page: page+1) : nil
            )
        }
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
