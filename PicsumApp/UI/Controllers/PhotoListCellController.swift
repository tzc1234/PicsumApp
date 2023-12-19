//
//  PhotoListCellController.swift
//  PicsumApp
//
//  Created by Tsz-Lung on 05/07/2023.
//

import UIKit

final class PhotoListCellController {
    private(set) var cell: PhotoListCell?
    
    let viewModel: PhotoImageViewModel<UIImage> // expose for testing
    let selection: () -> Void
    
    init(viewModel: PhotoImageViewModel<UIImage>, selection: @escaping () -> Void) {
        self.viewModel = viewModel
        self.selection = selection
    }
    
    func cell(in collectionView: UICollectionView, for indexPath: IndexPath) -> PhotoListCell {
        cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: PhotoListCell.identifier,
            for: indexPath) as? PhotoListCell
        cell?.contentView.layoutIfNeeded()
        cell?.imageView.image = nil
        setupBindings()
        load()
        return cell!
    }
    
    private func setupBindings() {
        viewModel.onLoadImage = { [weak self] isLoading in
            self?.cell?.isLoading = isLoading
        }
        
        viewModel.didLoadImage = { [weak self] image in
            self?.cell?.imageView.image = image
        }
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
