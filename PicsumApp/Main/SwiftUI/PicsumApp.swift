//
//  PicsumApp.swift
//  PicsumApp
//
//  Created by Tsz-Lung on 18/01/2024.
//

import SwiftUI

// ViewInspector not support `App` type, so the acceptance test starts from `ContentView`.
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
        .onChange(of: scenePhase) { oldValue, newValue in
            if oldValue == .active, newValue == .inactive {
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
