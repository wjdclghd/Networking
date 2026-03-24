//
//  AuthorizationProvider.swift
//  Networking
//
//  Created by jch on 3/22/26.
//

import Foundation

public protocol AuthorizationProvider: Sendable {
    var bearerToken: String? { get }
}
