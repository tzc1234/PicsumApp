//
//  Date+TestHelpers.swift
//  PicsumAppTests
//
//  Created by Tsz-Lung on 10/07/2023.
//

import Foundation

extension Date {
    func adding(days: Int) -> Date {
        Calendar(identifier: .gregorian).date(byAdding: .day, value: days, to: self)!
    }

    func adding(seconds: TimeInterval) -> Date {
        self + seconds
    }
}
