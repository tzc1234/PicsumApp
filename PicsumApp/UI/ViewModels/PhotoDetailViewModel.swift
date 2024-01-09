//
//  PhotoDetailViewModel.swift
//  PicsumApp
//
//  Created by Tsz-Lung on 16/07/2023.
//

import Foundation

final class PhotoDetailViewModel<Image> {
    var onLoad: Observer<Bool>?
    var didLoad: Observer<Image?>?
    var shouldReload: Observer<Bool>?
    var author: String { photo.author }
    var webURL: URL { photo.webURL }
    var width: Int { photo.width }
    var height: Int { photo.height }
    
    private let photo: Photo
    
    init(photo: Photo) {
        self.photo = photo
    }
    
    func didStartLoading() {
        onLoad?(true)
        shouldReload?(false)
    }
    
    func didFinishLoading(with image: Image?) {
        didLoad?(image)
        shouldReload?(false)
        onLoad?(false)
    }
    
    func didFinishLoadingWithError() {
        shouldReload?(true)
        onLoad?(false)
    }
    
    static var title: String {
        "Photo"
    }
}
