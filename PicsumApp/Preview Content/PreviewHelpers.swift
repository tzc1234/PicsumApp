//
//  PreviewHelpers.swift
//  PicsumApp
//
//  Created by Tsz-Lung on 20/01/2024.
//

import UIKit

var previewPhotos: [Photo] {
    [
        Photo(
            id: "0",
            author: "Author 0",
            width: 1,
            height: 1,
            webURL: URL(string: "https://any-url.com")!,
            url: URL(string: "https://0.com")!
        ),
        Photo(
            id: "1",
            author: "Author 1",
            width: 1,
            height: 1,
            webURL: URL(string: "https://any-url.com")!,
            url: URL(string: "https://1.com")!
        ),
        Photo(
            id: "2",
            author: "Author 2",
            width: 1,
            height: 1,
            webURL: URL(string: "https://any-url.com")!,
            url: URL(string: "https://2.com")!
        )
    ]
}

func getPreviewUIImage(by url: URL) -> UIImage {
    switch url.absoluteString {
    case "https://0.com":
        return .make(withColor: .red)
    case "https://1.com":
        return .make(withColor: .green)
    case "https://2.com":
        return .make(withColor: .blue)
    default:
        return .make(withColor: .gray)
    }
}
