//
//  PicsumApp.swift
//  PicsumApp
//
//  Created by Tsz-Lung on 18/01/2024.
//

import SwiftUI

final class PicsumAppComponentsFactory {
    private(set) lazy var client: HTTPClient = URLSessionHTTPClient(session: .shared)
    private(set) lazy var remoteImageDataLoader = RemoteImageDataLoader(client: client)
    
    private(set) lazy var storeURL = URL.applicationSupportDirectory.appending(path: "data-store.sqlite")
    private(set) lazy var imageDataStore: ImageDataStore? = try? SwiftDataImageDataStore(url: storeURL)
    private(set) lazy var localImageDataLoader = imageDataStore.map { LocalImageDataLoader(store: $0) }

    private(set) lazy var photosLoader = RemotePhotosLoader(client: client)
    private(set) lazy var imageDataLoader = makeImageDataLoader()
    private(set) lazy var photoImageDataLoader = PhotoImageDataLoaderAdapter(imageDataLoader: imageDataLoader)

    func makeImageDataLoader() -> ImageDataLoader {
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

@main
struct PicsumApp: App {
    private let factory = PicsumAppComponentsFactory()
    
    var body: some Scene {
        WindowGroup {
            PhotoGridComposer.composeWith(
                photosLoader: factory.photosLoader,
                imageLoader: factory.photoImageDataLoader, 
                nextView: { photo in
                    PhotoDetailContainerComposer.composeWith(photo: photo, imageDataLoader: factory.imageDataLoader)
                }
            )
        }
    }
}
