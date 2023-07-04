//
//  PhotoListCell.swift
//  PicsumApp
//
//  Created by Tsz-Lung on 04/07/2023.
//

import UIKit

final class PhotoListCell: UICollectionViewCell {
    let authorLabel = UILabel()
    let imageView = UIImageView()
    
    static var identifier: String { String(describing: self) }
}
