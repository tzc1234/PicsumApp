//
//  PhotoDetailIntegrationTests.swift
//  PicsumAppTests
//
//  Created by Tsz-Lung on 16/07/2023.
//

import XCTest
@testable import PicsumApp

class PhotoDetailViewController: UIViewController {
    private(set) lazy var authorLabel = UILabel()
    private(set) lazy var webURLLabel = UILabel()
    
    private let photo: Photo
    
    init(photo: Photo) {
        self.photo = photo
        super.init(nibName: nil, bundle: nil)
        self.title = "Photo"
    }
    
    required init?(coder: NSCoder) {
        nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        authorLabel.text = photo.author
        webURLLabel.text = photo.webURL.absoluteString
    }
    
}

final class PhotoDetailIntegrationTests: XCTestCase {

    func test_init_hasTitle() {
        let sut = PhotoDetailViewController(photo: makePhoto())
        
        XCTAssertEqual(sut.title, "Photo")
    }
    
    func test_detailView_rendersPhotoCorrectly() {
        let photo = makePhoto(author: "author0", webURL: URL(string: "https://web0-url.com")!)
        let sut = PhotoDetailViewController(photo: photo)
        
        sut.layoutIfNeeded()
        
        XCTAssertEqual(sut.authorText, photo.author)
        XCTAssertEqual(sut.webURLText, photo.webURL.absoluteString)
    }

}

extension PhotoDetailViewController {
    func layoutIfNeeded() {
        view.layoutIfNeeded()
    }
    
    var authorText: String? {
        authorLabel.text
    }
    
    var webURLText: String? {
        webURLLabel.text
    }
}
