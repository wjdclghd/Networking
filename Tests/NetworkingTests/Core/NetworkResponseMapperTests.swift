//
//  NetworkResponseMapperTests.swift
//  Networking
//
//  Created by jch on 5/10/26.
//

import Foundation
import XCTest
@testable import Networking

/// `NetworkResponseMapper`의 HTTP 성공/실패 변환을 검증합니다.
final class NetworkResponseMapperTests: XCTestCase {

    func test_map_whenStatusCodeIs2xx_returnsData() throws {
        // given
        let expectedData = Data("ok".utf8)

        // when
        let data = try NetworkResponseMapper.map(statusCode: 200, data: expectedData)

        // then
        XCTAssertEqual(data, expectedData)
    }

    func test_map_whenErrorBodyIsCommonPayload_throwsHTTPErrorWithPayload() throws {
        // when / then
        XCTAssertThrowsError(
            try NetworkResponseMapper.map(statusCode: 401, data: SampleResponseData.invalidCredentialsError)
        ) { error in
            guard case let NetworkError.http(httpError) = error else {
                XCTFail("Expected .http, got \(error)")
                return
            }

            XCTAssertEqual(httpError.statusCode, 401)
            XCTAssertEqual(httpError.payload?.code, "AUTH_INVALID_CREDENTIALS")
            XCTAssertEqual(httpError.payload?.message, "이메일 또는 비밀번호가 올바르지 않습니다.")
            XCTAssertEqual(httpError.payload?.timestamp, "2026-05-10T09:00:00Z")
            XCTAssertEqual(httpError.data, SampleResponseData.invalidCredentialsError)
        }
    }

    func test_map_whenStatusCodeIs400_preservesValidationDetails() throws {
        // when / then
        XCTAssertThrowsError(
            try NetworkResponseMapper.map(statusCode: 400, data: SampleResponseData.invalidRequestError)
        ) { error in
            guard case let NetworkError.http(httpError) = error else {
                XCTFail("Expected .http, got \(error)")
                return
            }

            XCTAssertEqual(httpError.statusCode, 400)
            XCTAssertEqual(httpError.payload?.code, "INVALID_REQUEST")
            XCTAssertEqual(httpError.payload?.details, ["email: must be a well-formed email address"])
        }
    }

    func test_map_whenStatusCodeIs409_preservesDuplicateEmailCode() throws {
        // when / then
        XCTAssertThrowsError(
            try NetworkResponseMapper.map(statusCode: 409, data: SampleResponseData.duplicateEmailError)
        ) { error in
            guard case let NetworkError.http(httpError) = error else {
                XCTFail("Expected .http, got \(error)")
                return
            }

            XCTAssertEqual(httpError.statusCode, 409)
            XCTAssertEqual(httpError.payload?.code, "AUTH_DUPLICATE_EMAIL")
        }
    }

    func test_map_whenStatusCodeIs429_preservesRateLimitCode() throws {
        // when / then
        XCTAssertThrowsError(
            try NetworkResponseMapper.map(statusCode: 429, data: SampleResponseData.rateLimitExceededError)
        ) { error in
            guard case let NetworkError.http(httpError) = error else {
                XCTFail("Expected .http, got \(error)")
                return
            }

            XCTAssertEqual(httpError.statusCode, 429)
            XCTAssertEqual(httpError.payload?.code, "RATE_LIMIT_EXCEEDED")
        }
    }

    func test_map_whenErrorBodyIsNotCommonPayload_throwsHTTPErrorWithoutPayload() throws {
        // given
        let data = Data("server-error".utf8)

        // when / then
        XCTAssertThrowsError(
            try NetworkResponseMapper.map(statusCode: 500, data: data)
        ) { error in
            guard case let NetworkError.http(httpError) = error else {
                XCTFail("Expected .http, got \(error)")
                return
            }

            XCTAssertEqual(httpError.statusCode, 500)
            XCTAssertNil(httpError.payload)
            XCTAssertEqual(httpError.data, data)
        }
    }
}
