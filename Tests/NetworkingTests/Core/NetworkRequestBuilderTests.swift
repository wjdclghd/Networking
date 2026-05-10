//
//  NetworkRequestBuilderTests.swift
//  Networking
//
//  Created by jch on 3/22/26.
//

import Foundation
import XCTest
@testable import Networking

/// `NetworkRequestBuilder`의 URLRequest 변환, header 처리, body 인코딩을 검증합니다.
final class NetworkRequestBuilderTests: XCTestCase {

    func test_build_whenPlainRequest_setsMethodURLAndQueryItems() throws {
        // given
        let sut = makeSUT()
        let endpoint = Endpoint(
            baseURL: try makeURL("https://example.com"),
            path: "/search",
            method: .get,
            queryItems: [
                URLQueryItem(name: "q", value: "swift"),
                URLQueryItem(name: "page", value: "1")
            ]
        )

        // when
        let request = try sut.build(from: endpoint)

        // then
        XCTAssertEqual(request.httpMethod, "GET")
        XCTAssertEqual(request.url?.absoluteString, "https://example.com/search?q=swift&page=1")
        XCTAssertNil(request.httpBody)
    }

    func test_build_withDefaultHeaders_appliesDefaultHeadersToRequest() throws {
        // given
        let sut = makeSUT(defaultHeaders: [
            "X-App-Version": "1.0.0",
            "Accept-Language": "ko"
        ])
        let endpoint = Endpoint(
            baseURL: try makeURL("https://example.com"),
            path: "/users/me",
            method: .get
        )

        // when
        let request = try sut.build(from: endpoint)

        // then
        XCTAssertEqual(request.value(forHTTPHeaderField: "X-App-Version"), "1.0.0")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Accept-Language"), "ko")
    }

    func test_build_whenEndpointHeadersConflict_overridesDefaultHeaders() throws {
        // given
        let sut = makeSUT(defaultHeaders: [
            "Content-Type": "application/json",
            "X-App-Version": "1.0.0"
        ])
        let endpoint = Endpoint(
            baseURL: try makeURL("https://example.com"),
            path: "/users/me",
            method: .get,
            headers: ["Content-Type": "application/xml"]
        )

        // when
        let request = try sut.build(from: endpoint)

        // then
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/xml")
        XCTAssertEqual(request.value(forHTTPHeaderField: "X-App-Version"), "1.0.0")
    }

    func test_build_whenAuthorizationIsRequired_setsAuthorizationHeader() throws {
        // given
        let sut = makeSUT(token: "access-token")
        let endpoint = Endpoint(
            baseURL: try makeURL("https://example.com"),
            path: "/protected",
            method: .get,
            requiresAuthorization: true
        )

        // when
        let request = try sut.build(from: endpoint)

        // then
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer access-token")
    }

    func test_build_whenAuthorizationIsRequiredWithoutToken_throwsMissingAuthorization() throws {
        // given
        let sut = makeSUT(token: nil)
        let endpoint = Endpoint(
            baseURL: try makeURL("https://example.com"),
            path: "/protected",
            method: .get,
            requiresAuthorization: true
        )

        // when / then
        XCTAssertThrowsError(try sut.build(from: endpoint)) { error in
            switch error {
            case NetworkError.missingAuthorization:
                XCTAssertTrue(true)
            default:
                XCTFail("Expected .missingAuthorization, got \(error)")
            }
        }
    }

    func test_build_whenJSONEncodableTask_setsHTTPBodyAndContentType() throws {
        // given
        let sut = makeSUT()
        let endpoint = Endpoint(
            baseURL: try makeURL("https://example.com"),
            path: "/search",
            method: .post,
            task: .jsonEncodable(AnyEncodable(RequestBodyFixture(keyword: "swift", page: 1)))
        )

        // when
        let request = try sut.build(from: endpoint)

        // then
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/json")

        let jsonObject = try XCTUnwrap(
            JSONSerialization.jsonObject(with: try XCTUnwrap(request.httpBody)) as? [String: Any]
        )
        XCTAssertEqual(jsonObject["keyword"] as? String, "swift")
        XCTAssertEqual(jsonObject["page"] as? Int, 1)
    }

    func test_build_whenJSONEncodingFails_throwsEncodingError() throws {
        // given
        let sut = makeSUT()
        let endpoint = Endpoint(
            baseURL: try makeURL("https://example.com"),
            path: "/search",
            method: .post,
            task: .jsonEncodable(AnyEncodable(StubEncodingFailure()))
        )

        // when / then
        XCTAssertThrowsError(try sut.build(from: endpoint)) { error in
            switch error {
            case NetworkError.encoding:
                XCTAssertTrue(true)
            default:
                XCTFail("Expected .encoding, got \(error)")
            }
        }
    }

    func test_build_whenFormURLEncodedTask_setsHTTPBodyAndContentType() throws {
        // given
        let sut = makeSUT()
        let endpoint = Endpoint(
            baseURL: try makeURL("https://example.com"),
            path: "/login",
            method: .post,
            task: .formURLEncoded([
                "email": "test@example.com",
                "password": "1234"
            ])
        )

        // when
        let request = try sut.build(from: endpoint)

        // then
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/x-www-form-urlencoded")

        let bodyData = try XCTUnwrap(request.httpBody)
        let bodyString = try XCTUnwrap(bodyData.toUTF8String())
        XCTAssertTrue(bodyString.contains("email=test@example.com") || bodyString.contains("email=test%40example.com"))
        XCTAssertTrue(bodyString.contains("password=1234"))
    }

    func test_build_whenCustomContentTypeAndJSONTask_doesNotOverrideContentType() throws {
        // given
        let sut = makeSUT()
        let endpoint = Endpoint(
            baseURL: try makeURL("https://example.com"),
            path: "/custom",
            method: .post,
            headers: ["Content-Type": "application/vnd.api+json"],
            task: .jsonEncodable(AnyEncodable(RequestBodyFixture(keyword: "swift", page: 1)))
        )

        // when
        let request = try sut.build(from: endpoint)

        // then
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/vnd.api+json")
    }

    func test_build_whenCustomContentTypeAndFormTask_doesNotOverrideContentType() throws {
        // given
        let sut = makeSUT()
        let endpoint = Endpoint(
            baseURL: try makeURL("https://example.com"),
            path: "/custom",
            method: .post,
            headers: ["Content-Type": "application/custom-form"],
            task: .formURLEncoded([
                "email": "test@example.com",
                "password": "1234"
            ])
        )

        // when
        let request = try sut.build(from: endpoint)

        // then
        XCTAssertEqual(request.value(forHTTPHeaderField: "Content-Type"), "application/custom-form")
    }
}

// MARK: - Helpers

private extension NetworkRequestBuilderTests {
    func makeSUT(
        token: String? = nil,
        timeoutInterval: TimeInterval = 30,
        cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy,
        defaultHeaders: [String: String] = [:]
    ) -> NetworkRequestBuilder {
        NetworkRequestBuilder(
            authorizationProvider: StaticBearerTokenProvider(token: token),
            configuration: NetworkConfiguration(
                timeoutInterval: timeoutInterval,
                cachePolicy: cachePolicy,
                defaultHeaders: defaultHeaders
            )
        )
    }
}
