//
//  NetworkErrorTests.swift
//  Networking
//
//  Created by jch on 3/22/26.
//

import Foundation
import XCTest
@testable import Networking

/// `NetworkError`의 각 case에 대한 `errorDescription` 반환값을 검증합니다.
final class NetworkErrorTests: XCTestCase {

    func test_errorDescription_whenInvalidURL_returnsExpectedMessage() {
        // given / when
        let sut = NetworkError.invalidURL

        // then
        XCTAssertEqual(sut.errorDescription, "유효하지 않은 URL입니다.")
    }

    func test_errorDescription_whenInvalidRequest_returnsExpectedMessage() {
        // given / when
        let sut = NetworkError.invalidRequest

        // then
        XCTAssertEqual(sut.errorDescription, "잘못된 요청입니다.")
    }

    func test_errorDescription_whenMissingAuthorization_returnsExpectedMessage() {
        // given / when
        let sut = NetworkError.missingAuthorization

        // then
        XCTAssertEqual(sut.errorDescription, "인증 정보가 없습니다.")
    }

    func test_errorDescription_whenTransport_returnsExpectedMessage() {
        // given / when
        let sut = NetworkError.transport(URLError(.notConnectedToInternet))

        // then
        XCTAssertTrue(sut.errorDescription?.contains("네트워크 전송 오류") == true)
    }

    func test_errorDescription_whenHTTPErrorWithoutPayload_returnsExpectedMessage() {
        // given / when
        let sut = NetworkError.http(NetworkHTTPError(statusCode: 500))

        // then
        XCTAssertEqual(sut.errorDescription, "HTTP 오류가 발생했습니다. statusCode: 500")
    }

    func test_errorDescription_whenHTTPErrorWithPayload_returnsPayloadMessage() {
        // given
        let payload = NetworkErrorPayload(
            code: "AUTH_INVALID_CREDENTIALS",
            message: "이메일 또는 비밀번호가 올바르지 않습니다.",
            details: [],
            timestamp: "2026-05-10T09:00:00Z"
        )

        // when
        let sut = NetworkError.http(NetworkHTTPError(statusCode: 401, payload: payload))

        // then
        XCTAssertEqual(sut.errorDescription, "이메일 또는 비밀번호가 올바르지 않습니다.")
    }

    func test_errorDescription_whenDecoding_returnsExpectedMessage() {
        // given / when
        let sut = NetworkError.decoding(DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "bad data")))

        // then
        XCTAssertTrue(sut.errorDescription?.contains("디코딩 오류") == true)
    }

    func test_errorDescription_whenUnknown_returnsExpectedMessage() {
        // given / when
        let sut = NetworkError.unknown

        // then
        XCTAssertEqual(sut.errorDescription, "알 수 없는 네트워크 오류입니다.")
    }

    func test_errorDescription_whenEncoding_returnsExpectedMessage() {
        // given / when
        let sut = NetworkError.encoding(EncodingFailureError.forcedFailure)

        // then
        XCTAssertTrue(sut.errorDescription?.contains("인코딩 오류") == true)
    }

    func test_errorDescription_whenTimeout_returnsExpectedMessage() {
        // given / when
        let sut = NetworkError.timeout

        // then
        XCTAssertEqual(sut.errorDescription, "요청 시간이 초과되었습니다.")
    }

    func test_errorDescription_whenCancelled_returnsExpectedMessage() {
        // given / when
        let sut = NetworkError.cancelled

        // then
        XCTAssertEqual(sut.errorDescription, "요청이 취소되었습니다.")
    }

    func test_errorDescription_whenEmptyResponse_returnsExpectedMessage() {
        // given / when
        let sut = NetworkError.emptyResponse

        // then
        XCTAssertEqual(sut.errorDescription, "응답 데이터가 비어 있습니다.")
    }
}
