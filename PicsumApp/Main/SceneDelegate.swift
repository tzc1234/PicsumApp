//
//  SceneDelegate.swift
//  PicsumApp
//
//  Created by Tsz-Lung on 03/07/2023.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    private lazy var client: HTTPClient = URLSessionHTTPClient(session: .shared)
    private lazy var remoteImageDataLoader = RemoteImageDataLoader(client: client)
    
    private lazy var storeURL = URL.applicationSupportDirectory.appending(path: "data-store.sqlite")
    private lazy var imageDataStore: ImageDataStore? = try? SwiftDataImageDataStore(url: storeURL)
    private lazy var localImageDataLoader = imageDataStore.map { LocalImageDataLoader(store: $0) }
    
    convenience init(client: HTTPClient, imageDataStore: ImageDataStore) {
        self.init()
        self.client = client
        self.imageDataStore = imageDataStore
    }
    
    var window: UIWindow?
    private var navigationController: UINavigationController?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let scene = (scene as? UIWindowScene) else { return }
        
        window = UIWindow(windowScene: scene)
        configureWindow()
    }
    
    func configureWindow() {
        let photosLoader = RemotePhotosLoader(client: client)
        let imageDataLoader = makeImageDataLoader()
        let photoImageLoader = PhotoImageDataLoaderAdapter(imageDataLoader: imageDataLoader)
        let photoListViewController = PhotoListComposer.composeWith(
            photosLoader: photosLoader,
            imageLoader: photoImageLoader,
            selection: { [weak self] photo in
                self?.showPhotoDetail(photo: photo, imageDataLoader: imageDataLoader)
            })
        
        navigationController = UINavigationController(rootViewController: photoListViewController)
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        Task {
            try? await localImageDataLoader?.invalidateImageData()
        }
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
    
    private func showPhotoDetail(photo: Photo, imageDataLoader: ImageDataLoader) {
        let vc = PhotoDetailComposer.composeWith(photo: photo, imageDataLoader: imageDataLoader)
        navigationController?.present(vc, animated: true)
    }
}
