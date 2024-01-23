//
//  SceneDelegate.swift
//  PicsumApp
//
//  Created by Tsz-Lung on 03/07/2023.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    private lazy var factory = AppComponentsFactory()
    
    convenience init(client: HTTPClient, imageDataStore: ImageDataStore) {
        self.init()
        self.factory = AppComponentsFactory(client: client, imageDataStore: imageDataStore)
    }
    
    var window: UIWindow?
    private var navigationController: UINavigationController?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let scene = (scene as? UIWindowScene) else { return }
        
        window = UIWindow(windowScene: scene)
        configureWindow()
    }
    
    func configureWindow() {
        let photoListViewController = PhotoListComposer.composeWith(
            photosLoader: factory.photosLoader,
            imageLoader: factory.photoImageDataLoader,
            selection: { [weak self] photo in
                guard let self else { return }
                
                showPhotoDetail(photo: photo, imageDataLoader: factory.imageDataLoader)
            })
        
        navigationController = UINavigationController(rootViewController: photoListViewController)
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        Task {
            try? await factory.localImageDataLoader?.invalidateImageData()
        }
    }
    
    private func showPhotoDetail(photo: Photo, imageDataLoader: ImageDataLoader) {
        let vc = PhotoDetailComposer.composeWith(photo: photo, imageDataLoader: imageDataLoader)
        navigationController?.present(vc, animated: true)
    }
}
