//
//  PhotoListViewController+TestHelpers.swift
//  PicsumAppTests
//
//  Created by Tsz-Lung on 05/07/2023.
//

import UIKit
@testable import PicsumApp

extension PhotoListViewController {
    public override func loadViewIfNeeded() {
        super.loadViewIfNeeded()
        
        collectionView.frame = CGRect(x: 0, y: 0, width: 1, height: 1)
    }
    
    func simulateUserInitiatedReload() {
        collectionView.refreshControl?.simulatePullToRefresh()
    }
    
    func simulateUserInitiatedLoadMore() {
        let scrollView = DraggingScrollView()
        scrollView.setContentOffset(.init(x: 0, y: 9999), animated: false)
        scrollViewDidScroll(scrollView)
    }
    
    var isShowingLoadingIndicator: Bool {
        collectionView.refreshControl?.isRefreshing == true
    }
    
    func numberOfRenderedPhotoView() -> Int {
        collectionView.numberOfSections > photoViewSection ? collectionView.numberOfItems(inSection: photoViewSection) : 0
    }
    
    func photoView(at item: Int) -> PhotoListCell? {
        let ds = collectionView.dataSource
        let indexPath = IndexPath(item: item, section: photoViewSection)
        return ds?.collectionView(collectionView, cellForItemAt: indexPath) as? PhotoListCell
    }
    
    @discardableResult
    func simulatePhotoViewVisible(at item: Int) -> PhotoListCell? {
        photoView(at: item)
    }
    
    func simulatePhotoViewInvisible(_ view: PhotoListCell, at item: Int) {
        let d = collectionView.delegate
        let indexPath = IndexPath(item: item, section: photoViewSection)
        d?.collectionView?(collectionView, didEndDisplaying: view, forItemAt: indexPath)
    }
    
    func simulatePhotoViewBecomeVisibleAgain(_ view: PhotoListCell, at item: Int) {
        let d = collectionView.delegate
        let indexPath = IndexPath(item: item, section: photoViewSection)
        d?.collectionView?(collectionView, willDisplay: view, forItemAt: indexPath)
    }
    
    private var photoViewSection: Int {
        0
    }
    
    var loadPhotosTask: Task<Void, Never>? {
        viewModel?.loadPhotosTask
    }
    
    var loadMorePhotosTask: Task<Void, Never>? {
        viewModel?.loadMorePhotosTask
    }
    
    func imageDataTask(at item: Int) -> Task<Void, Never>? {
        cellController(at: item)?.viewModel.imageDataTask
    }
    
    private func cellController(at item: Int) -> PhotoListCellController? {
        let indexPath = IndexPath(item: item, section: photoViewSection)
        let ds = collectionView.dataSource as? UICollectionViewDiffableDataSource<Int, PhotoListCellController>
        return ds?.itemIdentifier(for: indexPath)
    }
}

private class DraggingScrollView: UIScrollView {
    override var isDragging: Bool { true }
}
