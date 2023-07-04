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
    
    private lazy var dataSource: UICollectionViewDiffableDataSource<Int, Photo> = {
        .init(collectionView: collectionView) { [weak self] collectionView, indexPath, photo in
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PhotoListCell.identifier, for: indexPath) as! PhotoListCell
            cell.authorLabel.text = photo.author
            
            self?.imageDataTasks[indexPath] = Task {
                _ = try? await self?.imageLoader?.loadImageData(from: photo.url)
            }
            
            return cell
        }
    }()
    
    private(set) var reloadPhotosTask: Task<Void, Never>?
    private(set) var imageDataTasks = [IndexPath: Task<Void, Never>]()
    
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
    
    override func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        imageDataTasks[indexPath]?.cancel()
        imageDataTasks[indexPath] = nil
    }
}
