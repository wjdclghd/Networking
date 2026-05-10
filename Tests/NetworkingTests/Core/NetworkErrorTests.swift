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

    func test_errorDescription_whenServer_returnsExpectedMessage() {
        // given / when
        let sut = NetworkError.server(statusCode: 500, data: nil)

        // then
        XCTAssertEqual(sut.errorDescription, "서버 오류가 발생했습니다. statusCode: 500")
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

    func test_errorDescription_whenUnauthorized_returnsExpectedMessage() {
        // given / when
        let sut = NetworkError.unauthorized

        // then
        XCTAssertEqual(sut.errorDescription, "인증이 필요합니다.")
    }

    func test_errorDescription_whenForbidden_returnsExpectedMessage() {
        // given / when
        let sut = NetworkError.forbidden

        // then
        XCTAssertEqual(sut.errorDescription, "접근 권한이 없습니다.")
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
