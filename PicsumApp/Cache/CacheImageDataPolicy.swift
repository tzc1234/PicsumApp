//
//  CacheImageDataPolicy.swift
//  PicsumApp
//
//  Created by Tsz-Lung on 11/07/2023.
//

import Foundation

enum CacheImageDataPolicy {
    private static let calendar = Calendar(identifier: .gregorian)
    private static var maxCacheDays: Int { 7 }
    
    static func expirationDate(from date: Date) -> Date {
        calendar.date(byAdding: .day, value: -maxCacheDays, to: date)!
    }
}
