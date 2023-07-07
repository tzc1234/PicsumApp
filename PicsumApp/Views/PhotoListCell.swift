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
        l.textColor = .label
        l.font = .preferredFont(forTextStyle: .caption2)
        l.translatesAutoresizingMaskIntoConstraints = false
        return l
    }()
    
    private(set) lazy var imageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = .systemYellow
        iv.translatesAutoresizingMaskIntoConstraints = false
        return iv
    }()
    
    private lazy var blurView = {
        let bv = UIVisualEffectView(effect: UIBlurEffect(style: .light))
        bv.translatesAutoresizingMaskIntoConstraints = false
        return bv
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configureUI()
    }
    
    required init?(coder: NSCoder) {
        nil
    }
    
    private func configureUI() {
        contentView.addSubview(imageView)
        contentView.addSubview(blurView)
        contentView.addSubview(authorLabel)
        
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            
            blurView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            blurView.topAnchor.constraint(equalTo: authorLabel.topAnchor, constant: -4),
            
            authorLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 4),
            authorLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -4),
            authorLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -4)
        ])
    }
    
    static var identifier: String { String(describing: self) }
}
