//
//  WeakRefProxy.swift
//  PicsumAppTests
//
//  Created by Tsz-Lung on 22/01/2024.
//

import Foundation

final class WeakRefProxy<T: AnyObject> {
    private(set) weak var object: T?
    
    init(_ object: T) {
        self.object = object
    }
}
