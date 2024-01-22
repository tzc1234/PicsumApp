//
//  SceneDelegateTests.swift
//  PicsumAppTests
//
//  Created by Tsz-Lung on 15/07/2023.
//

import XCTest
@testable import PicsumApp

final class SceneDelegateTests: XCTestCase {

    func test_configureWindow_setsWindowAsKeyAndVisible() {
        let window = UIWindowSpy()
        let sut = SceneDelegate()
        sut.window = window
        
        sut.configureWindow()
        
        XCTAssertEqual(window.makeKeyAndVisibleCallCount, 1)
    }
    
    func test_configureWindow_configuresRootController() throws {
        let window = UIWindowSpy()
        let sut = SceneDelegate()
        sut.window = window
        
        sut.configureWindow()
        
        let root = try XCTUnwrap(window.rootViewController as? UINavigationController)
        XCTAssertTrue(
            root.topViewController is PhotoListViewController,
            "Expect PhotoListViewController found as the top viewController, got \(String(describing: root.topViewController)) instead")
    }

    // MARK: - Helpers
    
    private class UIWindowSpy: UIWindow {
        private(set) var makeKeyAndVisibleCallCount = 0
        
        override func makeKeyAndVisible() {
            makeKeyAndVisibleCallCount += 1
        }
    }
    
}
