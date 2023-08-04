//
//  XCTestCase+AssertThrows.swift
//  PicsumAppTests
//
//  Created by Tsz-Lung on 04/08/2023.
//

import XCTest

extension XCTestCase {
    func asyncAssertThrowsError(_ expression: @autoclosure () async throws -> Void,
                                _ message: String = "",
                                file: StaticString = #filePath,
                                line: UInt = #line,
                                _ errorHandler: (Error) -> Void = { _ in }) async {
        do {
            try await expression()
            XCTFail(message, file: file, line: line)
        } catch {
            errorHandler(error)
        }
    }
    
    func asyncAssertNoThrow(_ expression: @autoclosure () async throws -> Void,
                            _ message: String = "",
                            file: StaticString = #filePath,
                            line: UInt = #line) async {
        do {
            try await expression()
        } catch {
            XCTFail(message, file: file, line: line)
        }
    }
}
