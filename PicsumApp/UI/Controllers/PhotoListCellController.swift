//
//  PhotoListCellController.swift
//  PicsumApp
//
//  Created by Tsz-Lung on 05/07/2023.
//

import UIKit

protocol PhotoListCellControllerDelegate {
    var task: Task<Void, Never>? { get }
    func loadImage()
    func cancelLoad()
}

final class PhotoListCellController {
    private(set) var cell: PhotoListCell?
    
    var loadImageTask: Task<Void, Never>? {
        delegate.task
    }
    
    private let author: String
    private let delegate: PhotoListCellControllerDelegate
    private let setupBindings: (PhotoListCellController) -> Void
    let selection: () -> Void
    
    init(author: String,
         delegate: PhotoListCellControllerDelegate,
         setupBindings: @escaping (PhotoListCellController) -> Void,
         selection: @escaping () -> Void) {
        self.author = author
        self.delegate = delegate
        self.setupBindings = setupBindings
        self.selection = selection
    }
    
    func cell(in collectionView: UICollectionView, for indexPath: IndexPath) -> PhotoListCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: PhotoListCell.identifier,
            for: indexPath) as! PhotoListCell
        self.cell = cell
        cell.imageView.image = nil
        setupBindings(self)
        load()
        return cell
    }
    
    func load(for cell: UICollectionViewCell) {
        guard let newCell = cell as? PhotoListCell else { return }

        self.cell = newCell
        load()
    }
    
    private func load() {
        cell?.authorLabel.text = author
        delegate.loadImage()
    }
    
    func cancelLoad() {
        releaseForReuse()
        delegate.cancelLoad()
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
