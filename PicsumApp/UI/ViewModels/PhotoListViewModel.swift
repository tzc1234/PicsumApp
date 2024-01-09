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
    
    static var errorMessage: String {
        "Error occurred, please try again."
    }
    
    static var title: String {
        "Photos"
    }
}
