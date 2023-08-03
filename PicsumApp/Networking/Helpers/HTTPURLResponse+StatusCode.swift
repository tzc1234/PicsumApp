//
//  HTTPURLResponse+StatusCode.swift
//  PicsumApp
//
//  Created by Tsz-Lung on 04/08/2023.
//

import Foundation

extension HTTPURLResponse {
    var isOK: Bool {
        statusCode == 200
    }
}
