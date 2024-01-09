//
//  PhotoDetailViewController.swift
//  PicsumApp
//
//  Created by Tsz-Lung on 16/07/2023.
//

import UIKit

protocol PhotoDetailViewControllerDelegate {
    var task: Task<Void, Never>? { get }
    func loadImageData()
}

final class PhotoDetailViewController: UIViewController {
    private lazy var stackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.alignment = .leading
        sv.distribution = .fill
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()
    private(set) lazy var authorLabel = {
        let lbl = UILabel()
        lbl.font = .preferredFont(forTextStyle: .headline)
        return lbl
    }()
    private(set) lazy var webURLButton = {
        let btn = UIButton()
        btn.addTarget(self, action: #selector(openWeb), for: .touchUpInside)
        btn.isUserInteractionEnabled = true
        btn.titleLabel?.font = .preferredFont(forTextStyle: .subheadline)
        return btn
    }()
    
    private(set) lazy var imageContainerView = {
        let v = ShimmeringView()
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
    
    private var onViewIsAppearing: ((PhotoDetailViewController) -> Void)?
    
    var loadImageDataTask: Task<Void, Never>? {
        delegate.task
    }
    
    private let viewModel: PhotoDetailViewModel<UIImage>
    private let urlHandler: (URL) -> Void
    private let delegate: PhotoDetailViewControllerDelegate
    
    init(viewModel: PhotoDetailViewModel<UIImage>, urlHandler: @escaping (URL) -> Void,
         delegate: PhotoDetailViewControllerDelegate) {
        self.viewModel = viewModel
        self.urlHandler = urlHandler
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)
        self.title = PhotoDetailViewModel<UIImage>.title
    }
    
    required init?(coder: NSCoder) { nil }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setAuthorText()
        setWebURL()
        setupBindings()
        configureUI()
        onViewIsAppearing = { vc in
            vc.loadImage()
            vc.onViewIsAppearing = nil
        }
    }
    
    override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        
        onViewIsAppearing?(self)
    }
    
    private func setAuthorText() {
        authorLabel.text = viewModel.author
    }
    
    private func setWebURL() {
        let url = viewModel.webURL.absoluteString
        let attributedStr = NSMutableAttributedString(string: url)
        attributedStr.addAttribute(.link, value: url, range: .init(location: 0, length: url.count))
        webURLButton.setAttributedTitle(attributedStr, for: .normal)
    }
    
    private func setupBindings() {
        viewModel.onLoad = { [weak self] isLoading in
            self?.imageContainerView.isShimmering = isLoading
        }
        
        viewModel.didLoad = { [weak imageView] image in
            imageView?.image = image
        }
        
        viewModel.shouldReload = { [weak reloadButton] shouldReload in
            reloadButton?.isHidden = !shouldReload
        }
    }
    
    private func configureUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(imageContainerView)
        imageContainerView.addSubview(imageView)
        imageContainerView.addSubview(reloadButton)
        
        view.addSubview(stackView)
        stackView.addArrangedSubview(authorLabel)
        stackView.addArrangedSubview(webURLButton)
        
        let ratio = CGFloat(viewModel.height) / CGFloat(max(viewModel.width, 1))
        
        NSLayoutConstraint.activate([
            imageContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            imageContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            imageContainerView.centerYAnchor.constraint(lessThanOrEqualTo: view.centerYAnchor),
            imageContainerView.heightAnchor.constraint(equalTo: view.widthAnchor, multiplier: ratio),
            imageContainerView.bottomAnchor.constraint(lessThanOrEqualTo: stackView.topAnchor, constant: -8),
            
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
    }
    
    @objc private func openWeb() {
        urlHandler(viewModel.webURL)
    }
    
    @objc private func loadImage() {
        delegate.loadImageData()
    }
}
