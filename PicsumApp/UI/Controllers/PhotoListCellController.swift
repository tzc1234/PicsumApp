//
//  PhotoListCellController.swift
//  PicsumApp
//
//  Created by Tsz-Lung on 05/07/2023.
//

import UIKit

final class PhotoListCellController {
    private var cell: PhotoListCell?
    
    let viewModel: PhotoImageViewModel<UIImage> // expose for testing
    
    init(viewModel: PhotoImageViewModel<UIImage>) {
        self.viewModel = viewModel
    }
    
    func cell(in collectionView: UICollectionView, for indexPath: IndexPath) -> PhotoListCell {
        cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: PhotoListCell.identifier, for: indexPath) as? PhotoListCell
        cell?.imageView.image = nil
        setupBindings()
        load()
        return cell!
    }
    
    func load(for cell: UICollectionViewCell) {
        guard let newCell = cell as? PhotoListCell else { return }

        self.cell = newCell
        load()
    }
    
    private func load() {
        cell?.authorLabel.text = viewModel.author
        viewModel.loadImage()
    }
    
    func cancelLoad() {
        releaseForReuse()
        viewModel.cancelLoad()
    }
    
    private func setupBindings() {
        viewModel.onLoadImage = { [weak self] isLoading in
            self?.cell?.imageContainerView.isShimmering = isLoading
        }
        
        viewModel.didLoadImage = { [weak self] image in
            self?.cell?.imageView.image = image
        }
    }
    
    private func releaseForReuse() {
        cell = nil
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
