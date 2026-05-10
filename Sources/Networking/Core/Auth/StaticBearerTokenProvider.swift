//
//  StaticBearerTokenProvider.swift
//  Networking
//
//  Created by jch on 3/22/26.
//

import Foundation

/// 고정 bearer token을 반환하는 인증 제공자입니다.
public struct StaticBearerTokenProvider: AuthorizationProvider {
    /// Authorization header에 사용할 bearer token입니다.
    public let bearerToken: String?

    /// 고정 bearer token 제공자를 생성합니다.
    ///
    /// - Parameter token: Authorization header에 사용할 bearer token입니다.
    public init(token: String?) {
        self.bearerToken = token
    }
}
