//
//  Paginated.swift
//  PicsumApp
//
//  Created by Tsz-Lung on 20/12/2023.
//

import Foundation

struct Paginated<Item> {
    typealias LoadMore = (() async throws -> Paginated<Item>)
    
    let items: [Item]
    let loadMore: LoadMore?
    
    static var empty: Self {
        .init(items: [], loadMore: nil)
    }
}
