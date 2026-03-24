//
//  EncodingFailureMock.swift
//  Networking
//
//  Created by jch on 3/22/26.
//

import Foundation

enum MockEncodingError: Error {
    case forcedFailure
}

struct EncodingFailureMock: Encodable, Sendable {
    func encode(to encoder: Encoder) throws {
        throw MockEncodingError.forcedFailure
    }
}
