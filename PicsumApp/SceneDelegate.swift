//
//  SceneDelegate.swift
//  PicsumApp
//
//  Created by Tsz-Lung on 03/07/2023.
//

import CoreData
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let scene = (scene as? UIWindowScene) else { return }
        
        window = UIWindow(windowScene: scene)
        configureWindow()
    }
    
    func configureWindow() {
        let client = URLSessionHTTPClient(session: .shared)
        let photosLoader = RemotePhotosLoader(client: client)
        let remoteImageDataLoader = RemoteImageDataLoader(client: client)
        
        let storeURL = NSPersistentContainer.defaultDirectoryURL().appending(path: "data-store.sqlite")
        let imageDataStore = try! CoreDataImageDataStore(storeURL: storeURL)
        let localImageDataLoader = LocalImageDataLoader(store: imageDataStore)
        
        let imageDataLoader = ImageDataLoaderWithFallbackComposite(
            primary: localImageDataLoader,
            fallback: ImageDataLoaderCacheDecorator(
                loader: remoteImageDataLoader,
                cache: localImageDataLoader))
        
        let photoImageLoader = PhotoImageDataLoaderAdapter(imageDataLoader: imageDataLoader)
        let viewModel = PhotoListViewModel(loader: photosLoader)
        let photoListViewController = PhotoListComposer.composeWith(viewModel: viewModel, imageLoader: photoImageLoader)
        
        window?.rootViewController = UINavigationController(rootViewController: photoListViewController)
        window?.makeKeyAndVisible()
    }
}
