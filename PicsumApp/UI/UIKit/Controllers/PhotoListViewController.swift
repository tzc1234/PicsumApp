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
    
    private var onViewIsAppear: ((PhotoListViewController) -> Void)?
    
    var loadPhotosTask: Task<Void, Never>? {
        delegate?.loadPhotosTask
    }
    
    var loadMorePhotosTask: Task<Void, Never>? {
        delegate?.loadMorePhotosTask
    }
    
    private var viewModel: PhotoListViewModel?
    private var delegate: PhotosLoadingDelegate?
    
    convenience init(viewModel: PhotoListViewModel, delegate: PhotosLoadingDelegate) {
        self.init(collectionViewLayout: UICollectionViewFlowLayout())
        self.viewModel = viewModel
        self.delegate = delegate
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureCollectionView()
        setupBindings()
        onViewIsAppear = { vc in
            vc.reloadPhotos()
            vc.onViewIsAppear = nil
        }
    }
    
    override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        
        onViewIsAppear?(self)
    }
    
    private func configureCollectionView() {
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
        viewModel?.onLoad = { [weak self] isLoading in
            if isLoading {
                self?.collectionView.refreshControl?.beginRefreshing()
            } else {
                self?.collectionView.refreshControl?.endRefreshing()
            }
        }
        
        viewModel?.onError = { [weak self] message in
            message.map { self?.showErrorView(message: $0) }
        }
    }
    
    private func showErrorView(message: String) {
        let alert = UIAlertController(title: PhotoListViewModel.errorTitle, message: message, preferredStyle: .alert)
        alert.addAction(.init(title: "Cancel", style: .cancel))
        present(alert, animated: true)
    }
    
    @objc private func reloadPhotos() {
        delegate?.loadPhotos()
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
}

extension PhotoListViewController {
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView.isDragging else { return }
        
        if shouldLoadMorePhotos(to: scrollView) {
            delegate?.loadMorePhotos()
        }
    }
    
    private func shouldLoadMorePhotos(to scrollView: UIScrollView) -> Bool {
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let frameHeight = scrollView.frame.height
        return offsetY > contentHeight - frameHeight
    }
}
