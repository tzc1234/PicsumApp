//
//  PhotoListViewModel.swift
//  PicsumApp
//
//  Created by Tsz-Lung on 03/07/2023.
//

import Foundation

final class PhotoListViewModel {
    typealias Observer<T> = (T) -> Void
    
    var onLoad: Observer<Bool>?
    var onError: Observer<String?>?
    var didLoad: Observer<[Photo]>?
     
    private var photos = [Photo]()
    private var currentPage = 1
    private var hasMorePage = true
    private let loader: PhotosLoader
    
    init(loader: PhotosLoader) {
        self.loader = loader
    }
    
    func loadPhotos() async {
        resetCurrentPage()
        
        await loadPhotosFromLoader {
            photos = $0
            didLoad?(photos)
        }
    }
    
    func loadMorePhotos() async {
        guard hasMorePage else { return }
        
        await loadPhotosFromLoader {
            photos += $0
            didLoad?(photos)
        }
    }
    
    private func resetCurrentPage() {
        currentPage = 1
    }
    
    @MainActor
    private func loadPhotosFromLoader(completion: ([Photo]) -> Void) async {
        onLoad?(true)
        
        do {
            let photos = try await loader.load(page: currentPage)
            updatePaging(by: photos)
            completion(photos)
            onError?(nil)
        } catch {
            onError?(Self.errorMessage)
        }
        
        onLoad?(false)
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
