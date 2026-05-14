//
//  NetworkErrorPayload.swift
//  Networking
//
//  Created by jch on 5/10/26.
//

import Foundation

/// 서버 공통 에러 응답 body를 도메인 중립 형태로 보존합니다.
public struct NetworkErrorPayload: Decodable, Equatable, Sendable {
    /// 서버가 정의한 에러 코드입니다.
    public let code: String
    /// 서버가 전달한 에러 메시지입니다.
    public let message: String
    /// 유효성 검증 실패 등 상세 메시지입니다.
    public let details: [String]
    /// 에러가 발생한 시각 문자열입니다.
    public let timestamp: String?

    /// 서버 공통 에러 payload를 생성합니다.
    ///
    /// - Parameters:
    ///   - code: 서버가 정의한 에러 코드입니다.
    ///   - message: 서버가 전달한 에러 메시지입니다.
    ///   - details: 유효성 검증 실패 등 상세 메시지입니다.
    ///   - timestamp: 에러가 발생한 시각 문자열입니다.
    public init(
        code: String,
        message: String,
        details: [String] = [],
        timestamp: String? = nil
    ) {
        self.code = code
        self.message = message
        self.details = details
        self.timestamp = timestamp
    }
}
