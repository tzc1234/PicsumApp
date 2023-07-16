//
//  PhotoDetailViewController.swift
//  PicsumApp
//
//  Created by Tsz-Lung on 16/07/2023.
//

import UIKit

final class PhotoDetailViewController: UIViewController {
    private lazy var stackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = 8
        sv.alignment = .leading
        sv.distribution = .fill
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()
    private(set) lazy var authorLabel = {
        let l = UILabel()
        l.font = .preferredFont(forTextStyle: .headline)
        return l
    }()
    private(set) lazy var webURLLabel = {
        let l = UILabel()
        let tap = UITapGestureRecognizer(target: self, action: #selector(openWeb))
        l.addGestureRecognizer(tap)
        l.isUserInteractionEnabled = true
        l.font = .preferredFont(forTextStyle: .subheadline)
        return l
    }()
    
    private lazy var imageContainerView = {
        let v = UIView()
        v.backgroundColor = .systemGray5
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    private(set) lazy var imageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    private(set) lazy var reloadButton = {
        let btn = UIButton()
        let configuration = UIImage.SymbolConfiguration(pointSize: 70)
        let image = UIImage(systemName: "arrow.clockwise", withConfiguration: configuration)
        btn.setImage(image, for: .normal)
        btn.tintColor = .white
        btn.addTarget(self, action: #selector(loadImage), for: .touchUpInside)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.isHidden = true
        return btn
    }()
    
    private(set) var task: Task<Void, Never>?
    private(set) var isLoading = false {
        didSet {
            if isLoading {
                imageContainerView.startShimmering()
            } else {
                imageContainerView.stopShimmering()
            }
        }
    }
    
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
        setupLabels()
        configureUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if imageView.image == nil {
            loadImage()
        }
    }
    
    private func setupLabels() {
        authorLabel.text = photo.author
        
        let url = photo.webURL.absoluteString
        let attributedStr = NSMutableAttributedString(string: url)
        attributedStr.addAttribute(.link, value: url, range: .init(location: 0, length: url.count))
        webURLLabel.attributedText = attributedStr
    }
    
    private func configureUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(imageContainerView)
        imageContainerView.addSubview(imageView)
        imageContainerView.addSubview(reloadButton)
        
        view.addSubview(stackView)
        stackView.addArrangedSubview(authorLabel)
        stackView.addArrangedSubview(webURLLabel)
        
        let imageViewHeight = CGFloat(photo.height) * UIScreen.main.bounds.width / CGFloat(photo.width)
        
        NSLayoutConstraint.activate([
            imageContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imageContainerView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            imageContainerView.heightAnchor.constraint(equalToConstant: imageViewHeight),
            
            imageView.leadingAnchor.constraint(equalTo: imageContainerView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: imageContainerView.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: imageContainerView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: imageContainerView.bottomAnchor),
            
            reloadButton.centerXAnchor.constraint(equalTo: imageContainerView.centerXAnchor),
            reloadButton.centerYAnchor.constraint(equalTo: imageContainerView.centerYAnchor),
            
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -8),
            stackView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8)
        ])
        
        view.layoutIfNeeded()
    }
    
    @objc private func openWeb() {
        UIApplication.shared.open(photo.webURL)
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
