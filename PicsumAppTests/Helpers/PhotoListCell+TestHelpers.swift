//
//  PhotoListCell+TestHelpers.swift
//  PicsumAppTests
//
//  Created by Tsz-Lung on 05/07/2023.
//

import UIKit
@testable import PicsumApp

extension PhotoListCell {
    var authorText: String? {
        authorLabel.text
    }
    
    var isShowingImageLoadingIndicator: Bool {
        imageContainerView.isShimmering
    }
    
    var renderedImage: Data? {
        imageView.image?.pngData()
    }
}
