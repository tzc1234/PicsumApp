//
//  PhotoDetailViewController+TestHelpers.swift
//  PicsumAppTests
//
//  Created by Tsz-Lung on 16/07/2023.
//

import UIKit
@testable import PicsumApp

extension PhotoDetailViewController {
    func simulateAppearance() {
        beginAppearanceTransition(true, animated: false)
        endAppearanceTransition()
    }
    
    func simulateUserInitiatedReload() {
        reloadButton.simulate(event: .touchUpInside)
    }
    
    func simulateUserOpenPhotoDetailWeb() {
        webURLButton.simulate(event: .touchUpInside)
    }
    
    func completeImageDataLoading() async {
        await viewModel.task?.value
    }
    
    var authorText: String? {
        authorLabel.text
    }
    
    var webURLText: String? {
        webURLButton.titleLabel?.text
    }
    
    var imageData: Data? {
        imageView.image?.pngData()
    }
    
    var isShowingLoadingIndicator: Bool {
        imageContainerView.isShimmering
    }
    
    var isShowingReloadIndicator: Bool {
        !reloadButton.isHidden
    }
}
