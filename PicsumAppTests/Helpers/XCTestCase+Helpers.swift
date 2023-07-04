//
//  XCTestCase+Helpers.swift
//  PicsumAppTests
//
//  Created by Tsz-Lung on 04/07/2023.
//

import XCTest
@testable import PicsumApp

extension XCTestCase {
    func makePhoto(id: String = "any id", author: String = "any author",
                   width: Int = 1, height: Int = 1,
                   webURL: URL = URL(string: "https://any-web-url.com")!,
                   URL: URL = URL(string: "https://any-url.com")!) -> Photo {
        .init(id: id, author: author, width: width, height: height, webURL: webURL, url: URL)
    }
}
