//
//  NetworkClientProtocol.swift
//  Networking
//
//  Created by jch on 3/22/26.
//

import Foundation

/// Endpoint 기반 네트워크 요청을 실행합니다.
public protocol NetworkClientProtocol: Sendable {
    /// 요청을 실행하고 응답 body를 지정한 타입으로 디코딩합니다.
    ///
    /// - Parameters:
    ///   - endpoint: 실행할 요청 정보입니다.
    ///   - type: 디코딩할 응답 타입입니다.
    /// - Returns: 디코딩된 응답 값입니다.
    /// - Throws: 요청 생성, 전송, 응답 매핑, 디코딩 실패 시 `NetworkError`를 던집니다.
    func request<T: Decodable & Sendable>(
        _ endpoint: Endpoint,
        as type: T.Type
    ) async throws -> T

    /// 요청을 실행하고 응답 body를 원본 Data로 반환합니다.
    ///
    /// - Parameter endpoint: 실행할 요청 정보입니다.
    /// - Returns: 응답 body Data입니다.
    /// - Throws: 요청 생성, 전송, 응답 매핑 실패 시 `NetworkError`를 던집니다.
    func request(_ endpoint: Endpoint) async throws -> Data
}
