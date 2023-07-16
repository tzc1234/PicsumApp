//
//  PhotoDetailViewController+TestHelpers.swift
//  PicsumAppTests
//
//  Created by Tsz-Lung on 16/07/2023.
//

import UIKit
@testable import PicsumApp

extension PhotoDetailViewController {
    func layoutIfNeeded() {
        view.layoutIfNeeded()
    }
    
    func simulatePhotoDetailViewWillAppear() {
        viewWillAppear(false)
    }
    
    func simulateUserInitiatedReload() {
        reloadButton.simulate(event: .touchUpInside)
    }
    
    func simulateUserOpenPhotoDetailWeb() {
        webURLButton.simulate(event: .touchUpInside)
    }
    
    func completeTaskNow() async {
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
        isLoading
    }
    
    var isShowingReloadIndicator: Bool {
        !reloadButton.isHidden
    }
}
