//
//  PhotoListViewController.swift
//  PicsumApp
//
//  Created by Tsz-Lung on 04/07/2023.
//

import UIKit

final class PhotoListViewController: UICollectionViewController {
    var cellControllers = [PhotoListCellController]() {
        didSet { reloadCollectionView() }
    }
    
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
    
    private func reloadCollectionView() {
        var snapshot = NSDiffableDataSourceSnapshot<Int, PhotoListCellController>()
        snapshot.appendSections([0])
        snapshot.appendItems(cellControllers, toSection: 0)
        dataSource.applySnapshotUsingReloadData(snapshot)
    }
    
    override func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        cellControllers[indexPath.item].cancelLoad()
    }
    
    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        cellControllers[indexPath.item].load(for: cell as? PhotoListCell)
    }
}
