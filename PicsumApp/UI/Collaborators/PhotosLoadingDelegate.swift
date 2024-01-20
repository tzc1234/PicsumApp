//
//  PhotosLoadingDelegate.swift
//  PicsumApp
//
//  Created by Tsz-Lung on 20/01/2024.
//

import Foundation

protocol PhotosLoadingDelegate {
    var loadPhotosTask: Task<Void, Never>? { get }
    var loadMorePhotosTask: Task<Void, Never>? { get }
    func loadPhotos()
    func loadMorePhotos()
}
