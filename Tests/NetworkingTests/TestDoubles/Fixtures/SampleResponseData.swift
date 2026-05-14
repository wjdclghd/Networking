//
//  SampleResponseData.swift
//  Networking
//
//  Created by jch on 3/22/26.
//

import Foundation

enum SampleResponseData {
    static let validUser: Data = """
    {
      "id": 1,
      "name": "jch"
    }
    """.data(using: .utf8)!

    static let anotherUser: Data = """
    {
      "id": 2,
      "name": "ssbn"
    }
    """.data(using: .utf8)!

    static let invalidJSON: Data = """
    {
      "id":
    }
    """.data(using: .utf8)!

    static let empty = Data()

    static let serverError: Data = """
    {
      "message": "Internal Server Error"
    }
    """.data(using: .utf8)!

    static let invalidCredentialsError: Data = """
    {
      "code": "AUTH_INVALID_CREDENTIALS",
      "message": "이메일 또는 비밀번호가 올바르지 않습니다.",
      "details": [],
      "timestamp": "2026-05-10T09:00:00Z"
    }
    """.data(using: .utf8)!

    static let invalidRefreshTokenError: Data = """
    {
      "code": "AUTH_INVALID_REFRESH_TOKEN",
      "message": "Refresh Token이 올바르지 않습니다.",
      "details": [],
      "timestamp": "2026-05-10T09:00:00Z"
    }
    """.data(using: .utf8)!

    static let inactiveUserError: Data = """
    {
      "code": "AUTH_INACTIVE_USER",
      "message": "비활성화된 사용자입니다.",
      "details": [],
      "timestamp": "2026-05-10T09:00:00Z"
    }
    """.data(using: .utf8)!

    static let duplicateEmailError: Data = """
    {
      "code": "AUTH_DUPLICATE_EMAIL",
      "message": "이미 사용 중인 이메일입니다.",
      "details": [],
      "timestamp": "2026-05-10T09:00:00Z"
    }
    """.data(using: .utf8)!

    static let rateLimitExceededError: Data = """
    {
      "code": "RATE_LIMIT_EXCEEDED",
      "message": "요청 횟수가 너무 많습니다. 잠시 후 다시 시도해 주세요.",
      "details": [],
      "timestamp": "2026-05-10T09:00:00Z"
    }
    """.data(using: .utf8)!

    static let invalidRequestError: Data = """
    {
      "code": "INVALID_REQUEST",
      "message": "요청 값이 올바르지 않습니다.",
      "details": [
        "email: must be a well-formed email address"
      ],
      "timestamp": "2026-05-10T09:00:00Z"
    }
    """.data(using: .utf8)!
}
