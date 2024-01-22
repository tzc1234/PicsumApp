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

// Can't inspect from `PicsumApp`, so the acceptance test starts from `ContentView`.
struct ContentView: View {
    let factory: AppComponentsFactory
    let gridStore: PhotoGridStore
    let scenePhase: ScenePhase
    
    init(factory: AppComponentsFactory, scenePhase: ScenePhase) {
        self.factory = factory
        self.gridStore = PhotoGridComposer.makeGridStore(photosLoader: factory.photosLoader)
        self.scenePhase = scenePhase
    }
    
    var body: some View {
        VStack {
            PhotoGridComposer.makePhotoGridView(
                store: gridStore,
                imageLoader: factory.photoImageDataLoader,
                nextView: { photo in
                    PhotoDetailContainerComposer.composeWith(photo: photo, imageDataLoader: factory.imageDataLoader)
                })
        }
        .accessibilityIdentifier("content-view-outmost-stack")
        // ViewInspector not yet support the new iOS17 onChange modifier. So I use the old one.
        .onChange(of: scenePhase) { value in
            if scenePhase == .active, value == .inactive {
                Task {
                    try? await factory.localImageDataLoader?.invalidateImageData()
                }
            }
        }
    }
}

@main
struct PicsumApp: App {
    @Environment(\.scenePhase) private var scenePhase
    private let factory = AppComponentsFactory()
    
    var body: some Scene {
        WindowGroup {
            ContentView(factory: factory, scenePhase: scenePhase)
        }
    }
}
