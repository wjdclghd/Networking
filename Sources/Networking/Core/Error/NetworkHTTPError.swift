//
//  NetworkHTTPError.swift
//  Networking
//
//  Created by jch on 5/10/26.
//

import Foundation

/// HTTP 응답을 받은 실패 상태를 표현합니다.
public struct NetworkHTTPError: Equatable, Sendable {
    /// HTTP status code입니다.
    public let statusCode: Int
    /// 서버 공통 에러 payload입니다.
    public let payload: NetworkErrorPayload?
    /// 실패 응답의 원본 body data입니다.
    public let data: Data?

    /// HTTP 실패 정보를 생성합니다.
    ///
    /// - Parameters:
    ///   - statusCode: HTTP status code입니다.
    ///   - payload: 서버 공통 에러 payload입니다.
    ///   - data: 실패 응답의 원본 body data입니다.
    public init(
        statusCode: Int,
        payload: NetworkErrorPayload? = nil,
        data: Data? = nil
    ) {
        self.statusCode = statusCode
        self.payload = payload
        self.data = data
    }
}
