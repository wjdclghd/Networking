//
//  AuthorizationProviderAsync.swift
//  Networking
//
//  Created by jch on 3/23/26.
//

import Foundation

public protocol AuthorizationProviderAsync: Sendable {
    func bearerToken() async throws -> String?
}
