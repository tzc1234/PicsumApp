//
//  PhotoImageLoadingDelegate.swift
//  PicsumApp
//
//  Created by Tsz-Lung on 20/01/2024.
//

import Foundation

protocol PhotoImageLoadingDelegate {
    var task: Task<Void, Never>? { get }
    func loadImage()
    func cancelLoad()
}
