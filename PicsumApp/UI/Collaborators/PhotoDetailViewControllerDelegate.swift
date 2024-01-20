//
//  PhotoDetailViewControllerDelegate.swift
//  PicsumApp
//
//  Created by Tsz-Lung on 20/01/2024.
//

import Foundation

protocol PhotoDetailViewControllerDelegate {
    var task: Task<Void, Never>? { get }
    func loadImageData()
}
