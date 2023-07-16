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
    
    private(set) var task: Task<Void, Never>?
    
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
        
        task = Task {
            _ = try? await imageDataLoader.loadImageData(for: photo.url)
        }
    }
    
}

final class PhotoDetailIntegrationTests: XCTestCase {

    func test_init_hasTitle() {
        let (sut, _) = makeSUT()
        
        XCTAssertEqual(sut.title, "Photo")
    }
    
    @MainActor
    func test_detailView_rendersPhotoCorrectly() async {
        let photo = makePhoto(author: "author0", webURL: URL(string: "https://web0-url.com")!)
        let (sut, _) = makeSUT(photo: photo, dataStubs: [.success(anyData())])
        
        sut.layoutIfNeeded()
        await sut.completeTaskNow()
        
        assertThat(sut, hasConfiguredWith: photo)
    }
    
    @MainActor
    func test_detailView_requestsPhotoImageForURL() async {
        let photo = makePhoto(url: URL(string: "https://image-url.com")!)
        let (sut, loader) = makeSUT(photo: photo, dataStubs: [.success(anyData())])
        
        sut.layoutIfNeeded()
        await sut.completeTaskNow()
        
        XCTAssertEqual(loader.loggedURLs, [photo.url])
    }

    // MARK: - Helpers
    
    private func makeSUT(photo: Photo = makePhoto(),
                         dataStubs: [PhotosLoaderSpy.DataResult] = [],
                         file: StaticString = #filePath, line: UInt = #line) -> (sut: PhotoDetailViewController, loader: LoaderSpy) {
        let loader = LoaderSpy(dataStubs: dataStubs)
        let sut = PhotoDetailViewController(photo: photo, imageDataLoader: loader)
        trackForMemoryLeaks(loader, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, loader)
    }
    
    private func assertThat(_ sut: PhotoDetailViewController, hasConfiguredWith photo: Photo,
                            file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(sut.authorText, photo.author,
                       "Expect author is \(photo.author), got \(String(describing: sut.authorText)) instead",
                       file: file, line: line)
        XCTAssertEqual(sut.webURLText, photo.webURL.absoluteString,
                       "Expect webURL is \(photo.webURL.absoluteString), got \(String(describing: sut.webURLText)) instead",
                       file: file, line: line)
    }
    
    private class LoaderSpy: ImageDataLoader {
        typealias DataResult = Swift.Result<Data, Error>
        
        private(set) var dataStubs: [DataResult]
        private(set) var loggedURLs = [URL]()
        
        init(dataStubs: [DataResult]) {
            self.dataStubs = dataStubs
        }
        
        func loadImageData(for url: URL) async throws -> Data {
            loggedURLs.append(url)
            return try dataStubs.removeFirst().get()
        }
    }
    
}

extension PhotoDetailViewController {
    func layoutIfNeeded() {
        view.layoutIfNeeded()
    }
    
    func completeTaskNow() async {
        await task?.value
    }
    
    var authorText: String? {
        authorLabel.text
    }
    
    var webURLText: String? {
        webURLLabel.text
    }
}
