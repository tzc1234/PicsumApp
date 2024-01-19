//
//  PhotoDetailContainerComposer.swift
//  PicsumApp
//
//  Created by Tsz-Lung on 19/01/2024.
//

import SwiftUI

enum PhotoDetailContainerComposer {
    static func composeWith(photo: Photo) -> PhotoDetailContainer {
        let viewModel = PhotoDetailViewModel<UIImage>(photo: photo)
        let store = PhotoDetailStore(viewModel: viewModel)
        
        return PhotoDetailContainer(store: store)
    }
}
