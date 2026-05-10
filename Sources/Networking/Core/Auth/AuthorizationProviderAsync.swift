//
//  AuthorizationProviderAsync.swift
//  Networking
//
//  Created by jch on 3/23/26.
//

import Foundation

/// 비동기 방식으로 bearer token을 제공합니다.
public protocol AuthorizationProviderAsync: Sendable {
    /// Authorization header에 사용할 bearer token을 조회합니다.
    ///
    /// - Returns: 사용할 bearer token입니다.
    /// - Throws: token 조회 실패 시 원본 오류를 던집니다.
    func bearerToken() async throws -> String?
}
