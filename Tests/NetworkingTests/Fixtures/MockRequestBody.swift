//
//  MockRequestBody.swift
//  Networking
//
//  Created by jch on 3/22/26.
//

import Foundation

struct MockRequestBody: Encodable, Sendable {
    let keyword: String
    let page: Int
}
