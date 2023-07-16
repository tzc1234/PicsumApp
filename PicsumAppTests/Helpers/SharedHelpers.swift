//
//  XCTestCase+Helpers.swift
//  PicsumAppTests
//
//  Created by Tsz-Lung on 04/07/2023.
//

import XCTest
@testable import PicsumApp

func makePhoto(id: String = "any id", author: String = "any author",
               width: Int = 1, height: Int = 1,
               webURL: URL = URL(string: "https://any-web-url.com")!,
               url: URL = URL(string: "https://any-url.com")!) -> Photo {
    .init(id: id, author: author, width: width, height: height, webURL: webURL, url: url)
}

func anyNSError() -> NSError {
    NSError(domain: "error", code: 0)
}

func anyURL() -> URL {
    URL(string: "https://any-url.com")!
}

func anyData() -> Data {
    Data("any data".utf8)
}
