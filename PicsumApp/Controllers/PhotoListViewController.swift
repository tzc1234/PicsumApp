//
//  PhotoListViewController.swift
//  PicsumApp
//
//  Created by Tsz-Lung on 04/07/2023.
//

import UIKit

final class PhotoListViewController: UICollectionViewController {
    private lazy var refreshControl = {
        let refresh = UIRefreshControl()
        refresh.addTarget(self, action: #selector(reloadPhotos), for: .valueChanged)
        return refresh
    }()
    
    private lazy var dataSource: UICollectionViewDiffableDataSource<Int, PhotoListCellController> = {
        .init(collectionView: collectionView) { [weak self] collectionView, indexPath, cellController in
            cellController.cell(in: collectionView, for: indexPath)
        }
    }()
    
    private(set) var reloadPhotosTask: Task<Void, Never>?
    private(set) var cellControllers = [PhotoListCellController]()
    
    private var viewModel: PhotoListViewModel?
    private var imageLoader: ImageDataLoader?
    
    convenience init(viewModel: PhotoListViewModel, imageLoader: ImageDataLoader) {
        self.init(collectionViewLayout: UICollectionViewFlowLayout())
        self.title = PhotoListViewModel.title
        self.viewModel = viewModel
        self.imageLoader = imageLoader
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
            guard let self, let imageLoader = self.imageLoader else { return }
            
            self.display(photos.map { photo in
                PhotoListCellController(photo: photo, imageLoader: imageLoader)
            })
        }
        
        viewModel?.onError = { [weak self] message in
            self?.showErrorView(message: message)
        }
    }
    
    private func showErrorView(message: String?) {
        let alert = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alert.addAction(.init(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    @objc private func reloadPhotos() {
        reloadPhotosTask?.cancel()
        reloadPhotosTask = Task {
            await viewModel?.load()
        }
    }
    
    private func display(_ cellControllers: [PhotoListCellController]) {
        self.cellControllers = cellControllers
        var snapshot = NSDiffableDataSourceSnapshot<Int, PhotoListCellController>()
        snapshot.appendSections([0])
        snapshot.appendItems(cellControllers, toSection: 0)
        dataSource.applySnapshotUsingReloadData(snapshot)
    }
    
    override func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        cellControllers[indexPath.item].cancelImageLoading()
    }
    
    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        cellControllers[indexPath.item].startImageLoading()
    }
}
