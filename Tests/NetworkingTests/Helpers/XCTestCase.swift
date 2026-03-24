//
//  File.swift
//  Networking
//
//  Created by jch on 3/22/26.
//

import Foundation
import XCTest

extension XCTestCase {
    func makeURL(
        _ string: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws -> URL {
        try XCTUnwrap(URL(string: string), file: file, line: line)
    }
}
