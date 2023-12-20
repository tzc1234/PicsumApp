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
    
    func makePaginatedPhotos(page: Int = 1) async throws -> Paginated<Photo> {
        let url = PhotosEndpoint.get(page: page).url
        let photos = try await self.loader.load(for: url)
        let hasLoadMore = !photos.isEmpty
        return Paginated(
            items: photos,
            loadMore: hasLoadMore ? { try await self.makePaginatedPhotos(page: page+1) } : nil
        )
    }
}
