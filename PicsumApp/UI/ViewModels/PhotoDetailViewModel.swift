//
//  PhotoDetailViewModel.swift
//  PicsumApp
//
//  Created by Tsz-Lung on 16/07/2023.
//

import Foundation

struct PhotoDetail {
    let author: String
    let webURL: URL
    let width: Int
    let height: Int
}

final class PhotoDetailViewModel<Image> {
    var onLoad: Observer<Bool>?
    var didLoad: Observer<Image?>?
    var shouldReload: Observer<Bool>?
    
    var photoDetail: PhotoDetail {
        .init(author: photo.author, webURL: photo.webURL, width: photo.width, height: photo.height)
    }
    
    private let photo: Photo
    
    init(photo: Photo) {
        self.photo = photo
    }
    
    static var title: String {
        "Photo"
    }
}
