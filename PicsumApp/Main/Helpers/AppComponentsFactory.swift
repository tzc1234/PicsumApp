//
//  AppComponentsFactory.swift
//  PicsumApp
//
//  Created by Tsz-Lung on 23/01/2024.
//

import Foundation

final class AppComponentsFactory {
    private lazy var client: HTTPClient = URLSessionHTTPClient(session: .shared)
    private lazy var remoteImageDataLoader = RemoteImageDataLoader(client: client)
    
    private lazy var storeURL = URL.applicationSupportDirectory.appending(path: "data-store.sqlite")
    private lazy var imageDataStore: ImageDataStore? = try? SwiftDataImageDataStore(url: storeURL)
    private(set) lazy var localImageDataLoader = imageDataStore.map { LocalImageDataLoader(store: $0) }

    private(set) lazy var photosLoader = RemotePhotosLoader(client: client)
    private(set) lazy var imageDataLoader = makeImageDataLoader()
    private(set) lazy var photoImageDataLoader = PhotoImageDataLoaderAdapter(imageDataLoader: imageDataLoader)

    convenience init(client: HTTPClient, imageDataStore: ImageDataStore) {
        self.init()
        self.client = client
        self.imageDataStore = imageDataStore
    }
    
    private func makeImageDataLoader() -> ImageDataLoader {
        guard let localImageDataLoader else {
            return remoteImageDataLoader
        }
        
        return ImageDataLoaderWithFallbackComposite(
            primary: localImageDataLoader,
            fallback: ImageDataLoaderCacheDecorator(
                loader: remoteImageDataLoader,
                cache: localImageDataLoader))
    }
}
