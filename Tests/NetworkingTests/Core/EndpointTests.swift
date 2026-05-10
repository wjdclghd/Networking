//
//  EndpointTests.swift
//  Networking
//
//  Created by jch on 3/22/26.
//

import Foundation
import XCTest
@testable import Networking

/// `Endpoint` 초기화 시 프로퍼티 저장과 task 구성을 검증합니다.
final class EndpointTests: XCTestCase {

    func test_init_whenAllParametersProvided_storesAllProperties() throws {
        // given
        let baseURL = try makeURL("https://example.com")
        let queryItems = [
            URLQueryItem(name: "q", value: "swift"),
            URLQueryItem(name: "page", value: "1")
        ]

        // when
        let endpoint = Endpoint(
            baseURL: baseURL,
            path: "/search",
            method: .get,
            headers: ["X-Test": "true"],
            queryItems: queryItems,
            task: .plain,
            requiresAuthorization: true
        )

        // then
        XCTAssertEqual(endpoint.baseURL, baseURL)
        XCTAssertEqual(endpoint.path, "/search")
        XCTAssertEqual(endpoint.method, .get)
        XCTAssertEqual(endpoint.headers["X-Test"], "true")
        XCTAssertEqual(endpoint.queryItems.count, 2)
        XCTAssertEqual(endpoint.queryItems[0].name, "q")
        XCTAssertEqual(endpoint.queryItems[0].value, "swift")
        XCTAssertTrue(endpoint.requiresAuthorization)

        switch endpoint.task {
        case .plain:
            XCTAssertTrue(true)
        case .jsonEncodable:
            XCTFail("Expected .plain task")
        case .formURLEncoded:
            XCTFail("Expected .plain task")
        }
    }

    func test_init_whenJSONTask_storesJSONTask() throws {
        // given
        let baseURL = try makeURL("https://example.com")
        let body = RequestBodyFixture(keyword: "chatgpt", page: 1)

        // when
        let endpoint = Endpoint(
            baseURL: baseURL,
            path: "/v1/search",
            method: .post,
            task: .jsonEncodable(AnyEncodable(body))
        )

        // then
        switch endpoint.task {
        case .jsonEncodable:
            XCTAssertTrue(true)
        case .plain:
            XCTFail("Expected .jsonEncodable task")
        case .formURLEncoded:
            XCTFail("Expected .jsonEncodable task")
        }
    }

    func test_init_whenFormURLEncodedTask_storesFormURLEncodedTask() throws {
        // given
        let baseURL = try makeURL("https://example.com")

        // when
        let endpoint = Endpoint(
            baseURL: baseURL,
            path: "/login",
            method: .post,
            task: .formURLEncoded([
                "email": "test@example.com",
                "password": "1234"
            ])
        )

        // then
        switch endpoint.task {
        case .formURLEncoded(let parameters):
            XCTAssertEqual(parameters["email"], "test@example.com")
            XCTAssertEqual(parameters["password"], "1234")
        case .plain:
            XCTFail("Expected .formURLEncoded task")
        case .jsonEncodable:
            XCTFail("Expected .formURLEncoded task")
        }
    }
}
