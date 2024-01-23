//
//  Photo.swift
//  PicsumApp
//
//  Created by Tsz-Lung on 03/07/2023.
//

import Foundation

struct Photo: Equatable, Identifiable {
    let id, author: String
    let width, height: Int
    let webURL, url: URL
}
