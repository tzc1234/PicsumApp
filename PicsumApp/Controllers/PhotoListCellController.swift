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
    
    let viewModel: PhotoImageViewModel<UIImage> // expose for testing
    
    init(viewModel: PhotoImageViewModel<UIImage>) {
        self.viewModel = viewModel
    }
    
    @MainActor
    func cell(in collectionView: UICollectionView, for indexPath: IndexPath) -> PhotoListCell {
        cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: PhotoListCell.identifier, for: indexPath) as? PhotoListCell
        cell?.imageView.image = nil
        setupBindings()
        load()
        return cell!
    }
    
    @MainActor
    func load(for cell: UICollectionViewCell) {
        guard let newCell = cell as? PhotoListCell else { return }

        self.cell = newCell
        load()
    }
    
    @MainActor
    private func load() {
        cell?.authorLabel.text = viewModel.author
        imageDataTask = Task { [weak viewModel] in
            await viewModel?.loadImage()
        }
    }
    
    func cancelLoad() {
        imageDataTask?.cancel()
        imageDataTask = nil
        releaseForReuse()
    }
    
    @MainActor
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
