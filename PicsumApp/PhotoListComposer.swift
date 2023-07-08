//
//  PhotoListComposer.swift
//  PicsumApp
//
//  Created by Tsz-Lung on 05/07/2023.
//

import UIKit

enum PhotoListComposer {
    static func composeWith(viewModel: PhotoListViewModel, imageLoader: ImageDataLoader) -> PhotoListViewController {
        let viewController = PhotoListViewController(viewModel: viewModel)
        
        viewModel.didLoad = { [weak viewController] photos in
            viewController?.display(photos.map { photo in
                let viewModel = PhotoImageViewModel(
                    photo: photo,
                    imageLoader: imageLoader,
                    imageConverter: ImageDownsampleConverter.downsample)
                return PhotoListCellController(viewModel: viewModel)
            })
        }
        
        return viewController
    }
}

enum ImageDownsampleConverter {
    // https://medium.com/@zippicoder/downsampling-images-for-better-memory-consumption-and-uicollectionview-performance-35e0b4526425
    static func downsample(from data: Data) -> UIImage? {
        // Create an CGImageSource that represent an image
        let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, imageSourceOptions) else {
            return nil
        }
        
        // Calculate the desired dimension
        let scale = UIScreen.main.scale
        let pointSize = UIScreen.main.bounds.size
        let width: CGFloat = pointSize.width / 2
        let maxDimensionInPixels = width * scale
        
        // Perform downsampling
        let downsampleOptions = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimensionInPixels
        ] as [CFString: Any] as CFDictionary
        guard let downsampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampleOptions) else {
            return nil
        }
        
        // Return the downsampled image as UIImage
        return UIImage(cgImage: downsampledImage)
    }
}
