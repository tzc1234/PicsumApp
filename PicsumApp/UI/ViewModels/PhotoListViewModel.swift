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
    
    static var errorMessage: String {
        "Error occurred, please try again."
    }
    
    static var title: String {
        "Photos"
    }
}
