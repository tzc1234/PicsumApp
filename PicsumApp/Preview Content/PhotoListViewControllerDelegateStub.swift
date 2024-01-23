//
//  PhotoListViewControllerDelegateStub.swift
//  PicsumApp
//
//  Created by Tsz-Lung on 20/01/2024.
//

import Foundation

final class PhotoListViewControllerDelegateStub: PhotosLoadingDelegate {
    var loadPhotosTask: Task<Void, Never>?
    var loadMorePhotosTask: Task<Void, Never>?
    let viewModel: PhotoListViewModel
    
    private let stub: Result<[Photo], Error>
    
    init(viewModel: PhotoListViewModel = .init(), stub: Result<[Photo], Error>) {
        self.viewModel = viewModel
        self.stub = stub
    }
    
    func loadPhotos() {
        switch stub {
        case let .success(photos):
            viewModel.didFinishLoading(with: photos)
        case .failure:
            viewModel.didFinishLoadingWithError()
        }
    }
    
    func loadMorePhotos() {}
}
