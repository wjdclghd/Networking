//
//  UserResponseFixture.swift
//  Networking
//
//  Created by jch on 3/22/26.
//

import Foundation

struct UserResponseFixture: Decodable, Encodable, Equatable, Sendable {
    let id: Int
    let name: String
}
