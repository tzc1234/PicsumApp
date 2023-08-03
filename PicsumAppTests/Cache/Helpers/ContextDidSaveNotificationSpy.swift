//
//  ContextDidSaveNotificationSpy.swift
//  PicsumAppTests
//
//  Created by Tsz-Lung on 12/07/2023.
//

import Foundation

class ContextDidSaveNotificationSpy {
    private(set) var saveCount = 0
    
    init() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(contextDisSave),
                                               name: .NSManagedObjectContextDidSave,
                                               object: nil)
    }
    
    @objc private func contextDisSave() {
        saveCount += 1
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
