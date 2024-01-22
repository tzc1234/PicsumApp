//
//  PicsumApp.swift
//  PicsumApp
//
//  Created by Tsz-Lung on 18/01/2024.
//

import SwiftUI

final class AppComponentsFactory {
    private lazy var client: HTTPClient = URLSessionHTTPClient(session: .shared)
    private lazy var remoteImageDataLoader = RemoteImageDataLoader(client: client)
    
    private lazy var storeURL = URL.applicationSupportDirectory.appending(path: "data-store.sqlite")
    private lazy var imageDataStore: ImageDataStore? = try? SwiftDataImageDataStore(url: storeURL)
    private lazy var localImageDataLoader = imageDataStore.map { LocalImageDataLoader(store: $0) }

    private(set) lazy var photosLoader = RemotePhotosLoader(client: client)
    private lazy var imageDataLoader = makeImageDataLoader()
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

// Can't inspect from `PicsumApp`, so the acceptance test starts from `ContentView`.
struct ContentView: View {
    let factory: AppComponentsFactory
    let gridStore: PhotoGridStore
    
    init(factory: AppComponentsFactory) {
        self.factory = factory
        self.gridStore = PhotoGridComposer.makeGridStore(photosLoader: factory.photosLoader)
    }
    
    var body: some View {
        VStack {
            PhotoGridComposer.makePhotoGridView(
                store: gridStore,
                imageLoader: factory.photoImageDataLoader,
                nextView: { _ in
                    EmptyView()
                })
        }
    }
}

@main
struct PicsumApp: App {
    let factory = AppComponentsFactory()
    
    var body: some Scene {
        WindowGroup {
            ContentView(factory: factory)
        }
    }
}
