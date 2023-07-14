//
//  PhotoListCell.swift
//  PicsumApp
//
//  Created by Tsz-Lung on 04/07/2023.
//

import UIKit

final class PhotoListCell: UICollectionViewCell {
    private(set) lazy var authorLabel = {
        let l = UILabel()
        l.font = .preferredFont(forTextStyle: .caption1)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private(set) lazy var imageContainerView = {
        let v = UIView()
        v.backgroundColor = .systemGray5
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()
    
    private(set) lazy var imageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private lazy var placeholderView = {
        let configuration = UIImage.SymbolConfiguration(pointSize: 50)
        let image = UIImage(systemName: "photo", withConfiguration: configuration)
        let iv = UIImageView(image: image)
        iv.tintColor = .secondaryLabel
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private lazy var blurView = {
        let bv = UIVisualEffectView(effect: UIBlurEffect(style: .light))
        bv.translatesAutoresizingMaskIntoConstraints = false
        return bv
    }()
    
    var isShimmering = false {
        didSet {
            if isShimmering {
                imageContainerView.startShimmering()
            } else {
                imageContainerView.stopShimmering()
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
    }
    
    required init?(coder: NSCoder) {
        nil
    }
    
    private func configureUI() {
        contentView.layer.cornerRadius = 8
        contentView.clipsToBounds = true
        
        contentView.addSubview(imageContainerView)
        imageContainerView.addSubview(placeholderView)
        imageContainerView.addSubview(imageView)
        contentView.addSubview(blurView)
        contentView.addSubview(authorLabel)
        
        NSLayoutConstraint.activate([
            imageContainerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageContainerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageContainerView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageContainerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            placeholderView.centerXAnchor.constraint(equalTo: imageContainerView.centerXAnchor),
            placeholderView.centerYAnchor.constraint(equalTo: imageContainerView.centerYAnchor),
            
            imageView.leadingAnchor.constraint(equalTo: imageContainerView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: imageContainerView.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: imageContainerView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: imageContainerView.bottomAnchor),
            
            blurView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            blurView.topAnchor.constraint(equalTo: authorLabel.topAnchor, constant: -8),
            
            authorLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            authorLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            authorLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8)
        ])
    }
    
    static var identifier: String { String(describing: self) }
}
