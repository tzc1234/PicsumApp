//
//  UIControl+TestHelpers.swift
//  PicsumAppTests
//
//  Created by Tsz-Lung on 03/07/2023.
//

import UIKit

extension UIControl {
    func simulate(event: UIControl.Event) {
        allTargets.forEach { target in
            actions(forTarget: target, forControlEvent: event)?.forEach {
                (target as NSObject).perform(Selector($0))
            }
        }
    }
}
