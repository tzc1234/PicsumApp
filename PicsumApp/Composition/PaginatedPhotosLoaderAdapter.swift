//
//  PaginatedPhotosLoaderAdapter.swift
//  PicsumApp
//
//  Created by Tsz-Lung on 20/12/2023.
//

import Foundation

final class PaginatedPhotosLoaderAdapter {
    private let loader: PhotosLoader
    
    init(loader: PhotosLoader) {
        self.loader = loader
    }
    
    func makePaginatedPhotos(page: Int = 1) -> () async throws -> Paginated<Photo> {
        return { [weak self] in
            guard let self else { return .empty }
            
            let photos = try await self.loader.load(page: page)
            let hasLoadMore = !photos.isEmpty
            return Paginated(items: photos, loadMore: hasLoadMore ? self.makePaginatedPhotos(page: page+1) : nil)
        }
    }
}
