//
//  PhotoDetailViewController.swift
//  PicsumApp
//
//  Created by Tsz-Lung on 16/07/2023.
//

import UIKit

final class PhotoDetailViewController: UIViewController {
    private(set) lazy var authorLabel = UILabel()
    private(set) lazy var webURLLabel = UILabel()
    private(set) lazy var imageView = UIImageView()
    private(set) lazy var reloadButton = {
        let btn = UIButton()
        btn.addTarget(self, action: #selector(loadImage), for: .touchUpInside)
        return btn
    }()
    
    private(set) var task: Task<Void, Never>?
    private(set) var isLoading = false
    
    private let photo: Photo
    private let imageDataLoader: ImageDataLoader
    
    init(photo: Photo, imageDataLoader: ImageDataLoader) {
        self.photo = photo
        self.imageDataLoader = imageDataLoader
        super.init(nibName: nil, bundle: nil)
        self.title = "Photo"
    }
    
    required init?(coder: NSCoder) { nil }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        authorLabel.text = photo.author
        webURLLabel.text = photo.webURL.absoluteString
        loadImage()
    }
    
    @objc private func loadImage() {
        reloadButton.isHidden = true
        isLoading = true
        task = Task {
            do {
                imageView.image = UIImage(data: try await imageDataLoader.loadImageData(for: photo.url))
                reloadButton.isHidden = true
            } catch {
                reloadButton.isHidden = false
            }

            isLoading = false
        }
    }
}
