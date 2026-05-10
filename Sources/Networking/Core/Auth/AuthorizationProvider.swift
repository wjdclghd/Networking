//
//  AuthorizationProvider.swift
//  Networking
//
//  Created by jch on 3/22/26.
//

import Foundation

/// 요청 인증에 사용할 bearer token을 제공합니다.
public protocol AuthorizationProvider: Sendable {
    /// Authorization header에 사용할 bearer token입니다.
    var bearerToken: String? { get }
}
