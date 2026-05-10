//
//  RequestBodyFixture.swift
//  Networking
//
//  Created by jch on 3/22/26.
//

import Foundation

struct RequestBodyFixture: Encodable, Sendable {
    let keyword: String
    let page: Int
}
