//
//  UIRefreshControl+TestHelpers.swift
//  PicsumAppTests
//
//  Created by Tsz-Lung on 03/07/2023.
//

import UIKit

extension UIRefreshControl {
    func simulatePullToRefresh() {
        simulate(event: .valueChanged)
    }
}
