//
//  SceneDelegate.swift
//  PicsumApp
//
//  Created by Tsz-Lung on 03/07/2023.
//

import CoreData
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    private lazy var client = URLSessionHTTPClient(session: .shared)
    private lazy var remoteImageDataLoader = RemoteImageDataLoader(client: client)
    
    private let storeURL = NSPersistentContainer.defaultDirectoryURL().appending(path: "data-store.sqlite")
    private lazy var imageDataStore = {
        try? CoreDataImageDataStore(storeURL: storeURL)
    }()
    private lazy var localImageDataLoader: LocalImageDataLoader? = {
        guard let store = imageDataStore else { return nil }
        
        return LocalImageDataLoader(store: store)
    }()
    
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let scene = (scene as? UIWindowScene) else { return }
        
        window = UIWindow(windowScene: scene)
        configureWindow()
    }
    
    func configureWindow() {
        let photosLoader = RemotePhotosLoader(client: client)
        let photoImageLoader = PhotoImageDataLoaderAdapter(imageDataLoader: makeImageLoader())
        let viewModel = PhotoListViewModel(loader: photosLoader)
        let photoListViewController = PhotoListComposer.composeWith(viewModel: viewModel, imageLoader: photoImageLoader)
        
        window?.rootViewController = UINavigationController(rootViewController: photoListViewController)
        window?.makeKeyAndVisible()
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        Task {
            try? await localImageDataLoader?.invalidateImageData()
        }
    }
    
    private func makeImageLoader() -> ImageDataLoader {
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
