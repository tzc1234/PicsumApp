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
    
    private let viewModel: PhotoImageViewModel<UIImage>
    
    init(viewModel: PhotoImageViewModel<UIImage>) {
        self.viewModel = viewModel
    }
    
    @MainActor
    func cell(in collectionView: UICollectionView, for indexPath: IndexPath) -> PhotoListCell {
        cell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotoListCell.identifier, for: indexPath) as? PhotoListCell
        cell?.authorLabel.text = viewModel.author
        cell?.imageView.image = nil
        cell?.imageView.isShimmering = true
        setupBindings()
        load()
        return cell!
    }
    
    @MainActor
    func load() {
        imageDataTask = Task { [weak viewModel] in
            await viewModel?.loadImage()
        }
    }
    
    func cancelLoad() {
        imageDataTask?.cancel()
        imageDataTask = nil
    }
    
    @MainActor
    private func setupBindings() {
        viewModel.onLoadImage = { [weak cell] isLoading in
            cell?.imageView.isShimmering = isLoading
        }
        
        viewModel.didLoadImage = { [weak cell] image in
            cell?.imageView.image = image
        }
    }
}

extension PhotoListCellController: Hashable {
    static func == (lhs: PhotoListCellController, rhs: PhotoListCellController) -> Bool {
        lhs === rhs
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}
