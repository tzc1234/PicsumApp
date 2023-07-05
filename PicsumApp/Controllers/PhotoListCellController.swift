//
//  PhotoListCellController.swift
//  PicsumApp
//
//  Created by Tsz-Lung on 05/07/2023.
//

import UIKit

@MainActor
final class PhotoListCellController {
    private(set) var imageDataTask: Task<Void, Never>?
    private var cell: PhotoListCell?
    
    private let photo: Photo
    private let imageLoader: ImageDataLoader
    
    init(photo: Photo, imageLoader: ImageDataLoader) {
        self.photo = photo
        self.imageLoader = imageLoader
    }
    
    func cell(in collectionView: UICollectionView, for indexPath: IndexPath) -> PhotoListCell {
        cell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotoListCell.identifier, for: indexPath) as? PhotoListCell
        cell?.authorLabel.text = photo.author
        cell?.imageView.image = nil
        cell?.imageView.isShimmering = true
        startImageLoading()
        return cell!
    }
    
    func startImageLoading() {
        imageDataTask = Task { [url = photo.url, weak self] in
            self?.cell?.imageView.image = (try? await self?.imageLoader.loadImageData(from: url)).flatMap(UIImage.init)
            self?.cell?.imageView.isShimmering = false
        }
    }
    
    func cancelImageLoading() {
        imageDataTask?.cancel()
        imageDataTask = nil
    }
}

extension PhotoListCellController: Hashable {
    nonisolated static func == (lhs: PhotoListCellController, rhs: PhotoListCellController) -> Bool {
        lhs === rhs
    }
    
    nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(photo.id)
    }
}
