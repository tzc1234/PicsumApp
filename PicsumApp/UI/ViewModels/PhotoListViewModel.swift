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
     
    private var photos = [Photo]()
    private var currentPage = 1
    private var hasMorePage = true
    private(set) var loadPhotosTask: Task<Void, Never>?
    private(set) var loadMorePhotosTask: Task<Void, Never>?
    
    private let loader: PhotosLoader
    
    init(loader: PhotosLoader) {
        self.loader = loader
    }
    
    func loadPhotos() {
        resetCurrentPage()
        
        loadPhotosTask?.cancel()
        loadPhotosTask = loadPhotosFromLoader { [weak self] in
            self?.photos = $0
        }
    }
    
    func loadMorePhotos() {
        guard hasMorePage else { return }
        
        loadMorePhotosTask = loadPhotosFromLoader { [weak self] in
            self?.photos += $0
        }
    }
    
    private func resetCurrentPage() {
        currentPage = 1
    }
    
    private func loadPhotosFromLoader(completion: @escaping ([Photo]) -> Void) -> Task<Void, Never> {
        onLoad?(true)
        
        return Task { @MainActor in
            do {
                let photos = try await loader.load(page: currentPage)
                guard !Task.isCancelled else { return }
                
                updatePaging(by: photos)
                completion(photos)
                didLoad?(self.photos)
                onError?(nil)
            } catch {
                guard !Task.isCancelled else { return }
                
                onError?(Self.errorMessage)
            }
            
            onLoad?(false)
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
