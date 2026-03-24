//
//  StaticBearerTokenProvider.swift
//  Networking
//
//  Created by jch on 3/22/26.
//

import Foundation

public struct StaticBearerTokenProvider: AuthorizationProvider {
    public let bearerToken: String?
    
    public init(token: String?) {
        self.bearerToken = token
    }
}
