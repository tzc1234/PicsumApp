//
//  HTTPURLResponse+TestHelpers.swift
//  PicsumAppTests
//
//  Created by Tsz-Lung on 06/07/2023.
//

import Foundation

extension HTTPURLResponse {
    convenience init(statusCode: Int) {
        self.init(url: anyURL(), statusCode: statusCode, httpVersion: nil, headerFields: nil)!
    }
    
    static var ok200Response: HTTPURLResponse {
        .init(statusCode: 200)
    }
}
