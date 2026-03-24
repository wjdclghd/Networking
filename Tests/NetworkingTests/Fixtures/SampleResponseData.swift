//
//  File.swift
//  Networking
//
//  Created by jch on 3/22/26.
//

import Foundation

enum SampleResponseData {
    static let validUser: Data = """
    {
      "id": 1,
      "name": "jch"
    }
    """.data(using: .utf8)!

    static let anotherUser: Data = """
    {
      "id": 2,
      "name": "ssbn"
    }
    """.data(using: .utf8)!

    static let invalidJSON: Data = """
    {
      "id":
    }
    """.data(using: .utf8)!

    static let empty = Data()

    static let serverError: Data = """
    {
      "message": "Internal Server Error"
    }
    """.data(using: .utf8)!
}
