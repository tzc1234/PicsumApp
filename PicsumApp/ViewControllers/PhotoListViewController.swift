//
//  PhotoListViewController.swift
//  PicsumApp
//
//  Created by Tsz-Lung on 04/07/2023.
//

import UIKit

final class PhotoListViewController: UICollectionViewController {
    private(set) lazy var refreshControl = {
        let refresh = UIRefreshControl()
        refresh.addTarget(self, action: #selector(reloadPhotos), for: .valueChanged)
        return refresh
    }()
    
    private lazy var dataSource: UICollectionViewDiffableDataSource<Int, Photo> = {
        .init(collectionView: collectionView) { collectionView, indexPath, photo in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotoListCell.identifier, for: indexPath) as! PhotoListCell
            cell.authorLabel.text = photo.author
            return cell
        }
    }()
    
    private(set) var reloadPhotosTask: Task<Void, Never>?
    private var viewModel: PhotoListViewModel?
    
    convenience init(viewModel: PhotoListViewModel) {
        self.init(collectionViewLayout: UICollectionViewFlowLayout())
        self.title = PhotoListViewModel.title
        self.viewModel = viewModel
    }
    
    override func viewDidLoad() {
        collectionView.refreshControl = refreshControl
        collectionView.dataSource = dataSource
        collectionView.register(PhotoListCell.self, forCellWithReuseIdentifier: PhotoListCell.identifier)
        
        setupBindings()
        reloadPhotos()
    }
    
    private func setupBindings() {
        viewModel?.onLoad = { [weak self] isLoading in
            if isLoading {
                self?.refreshControl.beginRefreshing()
            } else {
                self?.refreshControl.endRefreshing()
            }
        }
        
        viewModel?.didLoad = { [weak self] photos in
            self?.display(photos)
        }
    }
    
    @objc private func reloadPhotos() {
        reloadPhotosTask?.cancel()
        reloadPhotosTask = Task {
            await viewModel?.load()
        }
    }
    
    private func display(_ photos: [Photo]) {
        var snapshot = NSDiffableDataSourceSnapshot<Int, Photo>()
        snapshot.appendSections([0])
        snapshot.appendItems(photos, toSection: 0)
        dataSource.applySnapshotUsingReloadData(snapshot)
    }
}
