//
//  HTTPTask.swift
//  Networking
//
//  Created by jch on 3/22/26.
//

import Foundation

public enum HTTPTask: Sendable {
    case plain
    case jsonEncodable(AnyEncodable)
    case formURLEncoded([String: String])
}
