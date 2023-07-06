//
//  PhotoListCellController.swift
//  PicsumApp
//
//  Created by Tsz-Lung on 05/07/2023.
//

import UIKit

final class PhotoListCellController {
    private(set) var imageDataTask: Task<Void, Never>?
    private var cell: PhotoListCell?
    
    private let photo: Photo
    private let imageLoader: ImageDataLoader
    
    init(photo: Photo, imageLoader: ImageDataLoader) {
        self.photo = photo
        self.imageLoader = imageLoader
    }
    
    @MainActor
    func cell(in collectionView: UICollectionView, for indexPath: IndexPath) -> PhotoListCell {
        cell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotoListCell.identifier, for: indexPath) as? PhotoListCell
        cell?.authorLabel.text = photo.author
        cell?.imageView.image = nil
        load(for: cell)
        return cell!
    }
    
    @MainActor
    func load(for cell: PhotoListCell?) {
        cell?.imageView.isShimmering = true
        imageDataTask = Task { [url = photo.url, weak self] in
            cell?.imageView.image = (try? await self?.imageLoader.loadImageData(from: url)).flatMap(UIImage.init)
            cell?.imageView.isShimmering = false
        }
    }
    
    func cancelLoad() {
        imageDataTask?.cancel()
        imageDataTask = nil
        releaseCellForReuse()
    }
    
    private func releaseCellForReuse() {
        cell = nil
    }
}

extension PhotoListCellController: Hashable {
    static func == (lhs: PhotoListCellController, rhs: PhotoListCellController) -> Bool {
        lhs === rhs
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(photo.id)
    }
}
