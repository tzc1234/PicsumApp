//
//  PhotoListViewController+TestHelpers.swift
//  PicsumAppTests
//
//  Created by Tsz-Lung on 05/07/2023.
//

import UIKit
@testable import PicsumApp

extension PhotoListViewController {
    func simulateAppearance() {
        replaceRefreshControlToSpyForiOS17()
        
        beginAppearanceTransition(true, animated: false)
        endAppearanceTransition()
        
        collectionView.frame = .init(x: 0, y: 0, width: 390, height: 9999)
    }
    
    private func replaceRefreshControlToSpyForiOS17() {
        let spy = RefreshControlSpy()
        
        let refreshControl = collectionView.refreshControl
        refreshControl?.allTargets.forEach { target in
            refreshControl?.actions(forTarget: target, forControlEvent: .valueChanged)?.forEach { action in
                spy.addTarget(target, action: Selector(action), for: .valueChanged)
            }
        }
        
        collectionView.refreshControl = spy
    }
    
    func simulateUserInitiatedReload() {
        collectionView.refreshControl?.simulatePullToRefresh()
    }
    
    func simulateUserInitiatedLoadMore() {
        let scrollView = DraggingScrollView()
        scrollView.setContentOffset(.init(x: 0, y: 9999), animated: false)
        scrollViewDidScroll(scrollView)
    }
    
    func simulatePhotoViewSelected(at item: Int) {
        let d = collectionView.delegate
        let indexPath = IndexPath(item: item, section: photoViewSection)
        d?.collectionView?(collectionView, didSelectItemAt: indexPath)
    }
    
    var isShowingLoadingIndicator: Bool {
        collectionView.refreshControl?.isRefreshing == true
    }
    
    func numberOfRenderedPhotoView() -> Int {
        collectionView.numberOfSections > photoViewSection ? collectionView.numberOfItems(inSection: photoViewSection) : 0
    }
    
    func photoView(at item: Int) -> PhotoListCell? {
        let indexPath = IndexPath(item: item, section: photoViewSection)
        return collectionView.cellForItem(at: indexPath) as? PhotoListCell
    }
    
    @discardableResult
    func simulatePhotoViewVisible(at item: Int) -> PhotoListCell? {
        let ds = collectionView.dataSource
        let indexPath = IndexPath(item: item, section: photoViewSection)
        return ds?.collectionView(collectionView, cellForItemAt: indexPath) as? PhotoListCell
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
    
    func completePhotosLoading() async {
        await loadPhotosTask?.value
    }
    
    func completeMorePhotosLoading() async {
        await loadMorePhotosTask?.value
    }
    
    func completeImageDataLoading(at item: Int) async {
        await cellController(at: item)?.loadImageTask?.value
    }
    
    private func cellController(at item: Int) -> PhotoListCellController? {
        let indexPath = IndexPath(item: item, section: photoViewSection)
        let ds = collectionView.dataSource as? UICollectionViewDiffableDataSource<Int, PhotoListCellController>
        return ds?.itemIdentifier(for: indexPath)
    }
}

extension PhotoListViewController {
    func loadMore() async {
        simulateUserInitiatedLoadMore()
        await completeMorePhotosLoading()
    }
    
    func renderedImage(at item: Int) async -> Data? {
        let view = simulatePhotoViewVisible(at: item)
        await completeImageDataLoading(at: item)
        return view?.renderedImage
    }
    
    func selectPhoto(at item: Int) {
        simulatePhotoViewSelected(at: item)
    }
}

private class DraggingScrollView: UIScrollView {
    override var isDragging: Bool { true }
}
