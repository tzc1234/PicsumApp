//
//  PhotoGridItem+Helpers.swift
//  PicsumAppTests
//
//  Created by Tsz-Lung on 18/01/2024.
//

import Foundation
@testable import PicsumApp

extension PhotoGridItem {
    var authorText: String {
        author
    }
    
    var imageData: Data? {
        image?.pngData()
    }
    
    var isShowingLoadingIndicator: Bool {
        isLoading
    }
}
