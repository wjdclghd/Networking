//
//  NetworkErrorTests.swift
//  Networking
//
//  Created by jch on 3/22/26.
//

import Foundation
import XCTest
@testable import Networking

final class NetworkErrorTests: XCTestCase {
    func test_errorDescription_invalidURL() {
        let sut = NetworkError.invalidURL

        XCTAssertEqual(sut.errorDescription, "유효하지 않은 URL입니다.")
    }

    func test_errorDescription_invalidRequest() {
        let sut = NetworkError.invalidRequest

        XCTAssertEqual(sut.errorDescription, "잘못된 요청입니다.")
    }

    func test_errorDescription_missingAuthorization() {
        let sut = NetworkError.missingAuthorization

        XCTAssertEqual(sut.errorDescription, "인증 정보가 없습니다.")
    }

    func test_errorDescription_transport() {
        let sut = NetworkError.transport(URLError(.notConnectedToInternet))

        XCTAssertTrue(sut.errorDescription?.contains("네트워크 전송 오류") == true)
    }

    func test_errorDescription_server() {
        let sut = NetworkError.server(statusCode: 500, data: nil)

        XCTAssertEqual(sut.errorDescription, "서버 오류가 발생했습니다. statusCode: 500")
    }

    func test_errorDescription_decoding() {
        let sut = NetworkError.decoding(DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "bad data")))

        XCTAssertTrue(sut.errorDescription?.contains("디코딩 오류") == true)
    }

    func test_errorDescription_unknown() {
        let sut = NetworkError.unknown

        XCTAssertEqual(sut.errorDescription, "알 수 없는 네트워크 오류입니다.")
    }
    
    func test_errorDescription_encoding() {
        let sut = NetworkError.encoding(MockEncodingError.forcedFailure)

        XCTAssertTrue(sut.errorDescription?.contains("인코딩 오류") == true)
    }

    func test_errorDescription_unauthorized() {
        let sut = NetworkError.unauthorized

        XCTAssertEqual(sut.errorDescription, "인증이 필요합니다.")
    }

    func test_errorDescription_forbidden() {
        let sut = NetworkError.forbidden

        XCTAssertEqual(sut.errorDescription, "접근 권한이 없습니다.")
    }

    func test_errorDescription_timeout() {
        let sut = NetworkError.timeout

        XCTAssertEqual(sut.errorDescription, "요청 시간이 초과되었습니다.")
    }

    func test_errorDescription_cancelled() {
        let sut = NetworkError.cancelled

        XCTAssertEqual(sut.errorDescription, "요청이 취소되었습니다.")
    }

    func test_errorDescription_emptyResponse() {
        let sut = NetworkError.emptyResponse

        XCTAssertEqual(sut.errorDescription, "응답 데이터가 비어 있습니다.")
    }
}
