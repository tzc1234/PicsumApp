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
    
    var isShowingLoadingIndicator: Bool {
        collectionView.refreshControl?.isRefreshing == true
    }
    
    func numberOfRenderedPhotoView() -> Int {
        collectionView.numberOfSections > photoViewSection ? collectionView.numberOfItems(inSection: photoViewSection) : 0
    }
    
    func photoView(at item: Int) -> PhotoListCell? {
        let ds = collectionView.dataSource
        let indexPath = IndexPath(item: item, section: 0)
        return ds?.collectionView(collectionView, cellForItemAt: indexPath) as? PhotoListCell
    }
    
    @discardableResult
    func simulatePhotoViewVisible(at item: Int) -> PhotoListCell? {
        photoView(at: item)
    }
    
    func simulatePhotoViewNotVisible(_ view: PhotoListCell, at item: Int) {
        let d = collectionView.delegate
        let indexPath = IndexPath(item: item, section: 0)
        d?.collectionView?(collectionView, didEndDisplaying: view, forItemAt: indexPath)
    }
    
    func simulatePhotoViewBecomeVisibleAgain(_ view: PhotoListCell, at item: Int) {
        let d = collectionView.delegate
        let indexPath = IndexPath(item: item, section: 0)
        d?.collectionView?(collectionView, willDisplay: view, forItemAt: indexPath)
    }
    
    private var photoViewSection: Int {
        0
    }
    
    func imageDataTask(at item: Int) -> Task<Void, Never>? {
        let indexPath = IndexPath(item: item, section: 0)
        let ds = collectionView.dataSource as? UICollectionViewDiffableDataSource<Int, PhotoListCellController>
        return ds?.itemIdentifier(for: indexPath)?.imageDataTask
    }
}
