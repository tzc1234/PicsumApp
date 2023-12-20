//
//  Paginated.swift
//  PicsumApp
//
//  Created by Tsz-Lung on 20/12/2023.
//

import Foundation

struct Paginated<Item> {
    let items: [Item]
    let loadMore: (() async throws -> Paginated<Item>)?
}
