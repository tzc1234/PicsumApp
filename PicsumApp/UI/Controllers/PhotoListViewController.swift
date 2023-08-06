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
    
    private(set) var viewModel: PhotoListViewModel?
    
    convenience init(viewModel: PhotoListViewModel) {
        self.init(collectionViewLayout: UICollectionViewFlowLayout())
        self.title = PhotoListViewModel.title
        self.viewModel = viewModel
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureConllectionView()
        setupBindings()
        reloadPhotos()
    }
    
    private func configureConllectionView() {
        collectionView.refreshControl = refreshControl
        collectionView.dataSource = dataSource
        collectionView.register(PhotoListCell.self, forCellWithReuseIdentifier: PhotoListCell.identifier)
        collectionView.collectionViewLayout = makeLayout()
    }
    
    private func makeLayout() -> UICollectionViewLayout {
        let layout = UICollectionViewFlowLayout()
        let spacing: CGFloat = 8
        layout.minimumInteritemSpacing = spacing
        layout.sectionInset = .init(top: spacing, left: spacing, bottom: spacing, right: spacing)
        layout.scrollDirection = .vertical
        
        let width = view.bounds.size.width
        let numberOfItemsPerRow: CGFloat = 2
        let availableWidth = width - spacing * (numberOfItemsPerRow + 1)
        let itemDimension = floor(availableWidth / numberOfItemsPerRow)
        layout.itemSize = .init(width: itemDimension, height: itemDimension)
        
        return layout
    }
    
    private func setupBindings() {
        viewModel?.onLoad = { [weak refreshControl] isLoading in
            if isLoading {
                refreshControl?.beginRefreshing()
            } else {
                refreshControl?.endRefreshing()
            }
        }
        
        viewModel?.onError = { [weak self] message in
            message.flatMap { self?.showErrorView(message: $0) }
        }
    }
    
    private func showErrorView(message: String) {
        let alert = UIAlertController(title: "Oops!", message: message, preferredStyle: .alert)
        alert.addAction(.init(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    @objc private func reloadPhotos() {
        viewModel?.loadPhotos()
    }
    
    func display(_ cellControllers: [PhotoListCellController]) {
        var snapshot = NSDiffableDataSourceSnapshot<Int, PhotoListCellController>()
        snapshot.appendSections([0])
        snapshot.appendItems(cellControllers, toSection: 0)
        dataSource.applySnapshotUsingReloadData(snapshot)
    }
    
    func displayMore(_ cellControllers: [PhotoListCellController]) {
        var snapshot = dataSource.snapshot()
        snapshot.appendItems(cellControllers, toSection: 0)
        dataSource.apply(snapshot, animatingDifferences: true)
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        cellController(forItemAt: indexPath)?.selection()
    }
    
    override func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        cellController(forItemAt: indexPath)?.cancelLoad()
    }
    
    override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        cellController(forItemAt: indexPath)?.load(for: cell)
    }
    
    private func cellController(forItemAt indexPath: IndexPath) -> PhotoListCellController? {
        dataSource.itemIdentifier(for: indexPath)
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView.isDragging else { return }
        
        if shouldLoadMorePhotos(to: scrollView) {
            viewModel?.loadMorePhotos()
        }
    }
    
    private func shouldLoadMorePhotos(to scrollView: UIScrollView) -> Bool {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let frameHeight = scrollView.frame.height
        return offsetY > contentHeight - frameHeight
    }
}
