//
//  PhotoImageViewModel.swift
//  PicsumApp
//
//  Created by Tsz-Lung on 06/07/2023.
//

import Foundation

final class PhotoImageViewModel<Image> {
    var onLoadImage: Observer<Bool>?
    var didLoadImage: Observer<Image?>?
    
    func didStartLoading() {
        onLoadImage?(true)
    }
    
    func didFinishLoading(with image: Image?) {
        didLoadImage?(image)
        onLoadImage?(false)
    }
}
