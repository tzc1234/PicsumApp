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
    
    private var currentPage = 1
    private var hasMorePage = true
    private var isLoadingMore = false
    private(set) var loadPhotosTask: Task<Void, Never>?
    private(set) var loadMorePhotosTask: Task<Void, Never>?
    
    private let loader: PhotosLoader
    
    init(loader: PhotosLoader) {
        self.loader = loader
    }
    
    func loadPhotos() {
        resetCurrentPage()
        onLoad?(true)
        
        loadPhotosTask?.cancel()
        loadPhotosTask = loadPhotosFromLoader(photosLoaded: { [weak self] photos in
            self?.didLoad?(photos)
        }, completion: { [weak self] in
            self?.onLoad?(false)
        })
    }
    
    private func resetCurrentPage() {
        currentPage = 1
    }
    
    func loadMorePhotos() {
        guard hasMorePage && !isLoadingMore else { return }
        
        isLoadingMore = true
        loadMorePhotosTask = loadPhotosFromLoader(photosLoaded: { [weak self] photos in
            self?.didLoadMore?(photos)
        }, completion: { [weak self] in
            self?.isLoadingMore = false
        })
    }
    
    private func loadPhotosFromLoader(photosLoaded: @escaping ([Photo]) -> Void,
                                      completion: @escaping () -> Void) -> Task<Void, Never> {
        Task { @MainActor in
            do {
                let photos = try await loader.load(page: currentPage)
                guard !Task.isCancelled else { return }
                
                updatePaging(by: photos)
                photosLoaded(photos)
                onError?(nil)
            } catch {
                guard !Task.isCancelled else { return }
                
                onError?(Self.errorMessage)
            }
            
            completion()
        }
    }
    
    private func updatePaging(by photos: [Photo]) {
        hasMorePage = !photos.isEmpty
        currentPage += 1
    }
    
    static var errorMessage: String {
        "Error occured, please try again."
    }
    
    static var title: String {
        "Photos"
    }
}
