//
//  TestUtility.swift
//  Networking
//
//  Created by jch on 3/22/26.
//

import Foundation

func makeHTTPURLResponse(
    url: URL,
    statusCode: Int,
    headers: [String: String]? = nil
) throws -> HTTPURLResponse {
    guard let response = HTTPURLResponse(
        url: url,
        statusCode: statusCode,
        httpVersion: nil,
        headerFields: headers
    ) else {
        throw URLError(.badServerResponse)
    }

    return response
}

extension Data {
    func toUTF8String() -> String? {
        String(data: self, encoding: .utf8)
    }
}
