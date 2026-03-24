//
//  EndpointTests.swift
//  Networking
//
//  Created by jch on 3/22/26.
//

import Foundation
import XCTest
@testable import Networking

final class EndpointTests: XCTestCase {
    func test_init_storesAllProperties() throws {
        let baseURL = try makeURL("https://example.com")
        let queryItems = [
            URLQueryItem(name: "q", value: "swift"),
            URLQueryItem(name: "page", value: "1")
        ]

        let endpoint = Endpoint(
            baseURL: baseURL,
            path: "/search",
            method: .get,
            headers: ["X-Test": "true"],
            queryItems: queryItems,
            task: .plain,
            requiresAuthorization: true
        )

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
        default:
            XCTFail("Expected .plain task")
        }
    }

    func test_init_whenUsingJSONTask_storesTask() throws {
        let baseURL = try makeURL("https://example.com")
        let body = MockRequestBody(keyword: "chatgpt", page: 1)

        let endpoint = Endpoint(
            baseURL: baseURL,
            path: "/v1/search",
            method: .post,
            task: .jsonEncodable(AnyEncodable(body))
        )

        switch endpoint.task {
        case .jsonEncodable:
            XCTAssertTrue(true)
        default:
            XCTFail("Expected .jsonEncodable task")
        }
    }

    func test_init_whenUsingFormTask_storesTask() throws {
        let baseURL = try makeURL("https://example.com")

        let endpoint = Endpoint(
            baseURL: baseURL,
            path: "/login",
            method: .post,
            task: .formURLEncoded([
                "email": "test@example.com",
                "password": "1234"
            ])
        )

        switch endpoint.task {
        case .formURLEncoded(let parameters):
            XCTAssertEqual(parameters["email"], "test@example.com")
            XCTAssertEqual(parameters["password"], "1234")
        default:
            XCTFail("Expected .formURLEncoded task")
        }
    }
}
