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
    
    func load() async {
        resetCurrentPage()
        
        await loadPhotosFromLoader {
            photos = $0
            didLoad?(photos)
        }
    }
    
    func loadMore() async {
        await loadPhotosFromLoader {
            photos += $0
            didLoad?(photos)
        }
    }
    
    private func resetCurrentPage() {
        currentPage = 1
    }
    
    private func loadPhotosFromLoader(completion: ([Photo]) -> Void) async {
        guard hasMorePage else { return }
        
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
        "Error occured, please reload again."
    }
}