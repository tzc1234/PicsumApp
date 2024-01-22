//
//  AcceptanceTestHelpers.swift
//  PicsumAppTests
//
//  Created by Tsz-Lung on 22/01/2024.
//

import XCTest
@testable import PicsumApp

protocol AcceptanceTest: XCTestCase {}
    
extension AcceptanceTest {
    func response(for url: URL) -> (Data, HTTPURLResponse) {
        let data = pagesData(for: url) ?? imagesData(for: url) ?? Data()
        return (data, .ok200Response)
    }
    
    func responseWithoutImageData(for url: URL) -> (Data, HTTPURLResponse) {
        (pagesData(for: url) ?? Data(), .ok200Response)
    }
    
    func pagesData(for url: URL) -> Data? {
        switch url.path() {
        case "/v2/list" where url.query()?.contains("page=1") == true:
            return page1Data()
        case "/v2/list" where url.query()?.contains("page=2") == true:
            return page2Data()
        default:
            return nil
        }
    }
    
    func imagesData(for url: URL) -> Data? {
        switch url.path() {
        case downloadURLFor(id: "0").path():
            return imageData0()
        case downloadURLFor(id: "1").path():
            return imageData1()
        case downloadURLFor(id: "2").path():
            return imageData2()
        default:
            return nil
        }
    }
    
    func firstPhoto() -> Photo {
        let json = page1Json()[0]
        return Photo(
            id: json["id"] as! String,
            author: json["author"] as! String,
            width: json["width"] as! Int,
            height: json["height"] as! Int,
            webURL: URL(string: json["url"] as! String)!,
            url: downloadURLFor(id: "0")
        )
    }
    
    func page1Data() -> Data {
        page1Json().toData()
    }
    
    private func page1Json() -> [[String: Any]] {
        [
            [
                "id": "0",
                "author": "author0",
                "width": 0,
                "height": 0,
                "url": "https://photo-0.com",
                "download_url": downloadURLFor(id: "0").absoluteString
            ],
            [
                "id": "1",
                "author": "author1",
                "width": 1,
                "height": 1,
                "url": "https://photo-1.com",
                "download_url": downloadURLFor(id: "1").absoluteString
            ]
        ]
    }
    
    func page2Data() -> Data {
        [
            [
                "id": "2",
                "author": "author2",
                "width": 2,
                "height": 2,
                "url": "https://photo-2.com",
                "download_url": downloadURLFor(id: "2").absoluteString
            ]
        ].toData()
    }
    
    func downloadURLFor(id: String, width: Int = .photoDimension, height: Int = .photoDimension) -> URL {
        URL(string: "https://picsum.photos/id/\(id)/\(width)/\(height)")!
    }
    
    func imageData0() -> Data {
        UIImage.makeData(withColor: .red)
    }
    
    func imageData1() -> Data {
        UIImage.makeData(withColor: .green)
    }
    
    func imageData2() -> Data {
        UIImage.makeData(withColor: .blue)
    }
}

private extension [[String: Any]] {
    func toData() -> Data {
        try! JSONSerialization.data(withJSONObject: self)
    }
}

private extension Int {
    static var photoDimension: Int { 600 }
}
