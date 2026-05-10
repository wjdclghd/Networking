//
//  URLSessionNetworkClientTests.swift
//  Networking
//
//  Created by jch on 3/22/26.
//

import Foundation
import XCTest
@testable import Networking

/// `URLSessionNetworkClient`의 요청 실행, 응답 디코딩, 에러 매핑을 검증합니다.
final class URLSessionNetworkClientTests: XCTestCase {

    // MARK: - Setup

    override func tearDownWithError() throws {
        StubURLProtocol.removeHandler()
        try super.tearDownWithError()
    }

    // MARK: - Tests

    func test_request_whenResponseIsSuccessful_returnsDecodedModel() async throws {
        // given
        let sut = makeSUT(
            token: "test-token",
            defaultHeaders: ["X-App-Version": "1.0.0"]
        )
        let endpoint = Endpoint(
            baseURL: try makeURL("https://example.com"),
            path: "/users/me",
            method: .get,
            queryItems: [URLQueryItem(name: "lang", value: "ko")],
            task: .plain,
            requiresAuthorization: true
        )
        let expectedDTO = UserResponseFixture(id: 1, name: "jch")

        StubURLProtocol.setRequestHandler { request in
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer test-token")
            XCTAssertEqual(request.value(forHTTPHeaderField: "X-App-Version"), "1.0.0")
            XCTAssertEqual(request.url?.absoluteString, "https://example.com/users/me?lang=ko")

            let response = try makeHTTPURLResponse(
                url: try XCTUnwrap(request.url),
                statusCode: 200
            )
            return (response, SampleResponseData.validUser)
        }

        // when
        let result = try await sut.request(endpoint, as: UserResponseFixture.self)

        // then
        XCTAssertEqual(result, expectedDTO)
    }

    func test_request_whenResponseIsSuccessful_returnsRawData() async throws {
        // given
        let sut = makeSUT()
        let endpoint = Endpoint(
            baseURL: try makeURL("https://example.com"),
            path: "/health",
            method: .get
        )
        let expectedData = Data("ok".utf8)

        StubURLProtocol.setRequestHandler { request in
            let response = try makeHTTPURLResponse(
                url: try XCTUnwrap(request.url),
                statusCode: 200
            )
            return (response, expectedData)
        }

        // when
        let result = try await sut.request(endpoint)

        // then
        XCTAssertEqual(result, expectedData)
    }

    func test_request_whenStatusCodeIsNot2xx_throwsServerError() async throws {
        // given
        let sut = makeSUT()
        let endpoint = Endpoint(
            baseURL: try makeURL("https://example.com"),
            path: "/users/me",
            method: .get
        )
        let expectedData = Data("server-error".utf8)

        StubURLProtocol.setRequestHandler { request in
            let response = try makeHTTPURLResponse(
                url: try XCTUnwrap(request.url),
                statusCode: 500
            )
            return (response, expectedData)
        }

        // when / then
        do {
            let _: UserResponseFixture = try await sut.request(endpoint, as: UserResponseFixture.self)
            XCTFail("Expected server error, but succeeded.")
        } catch let error as NetworkError {
            switch error {
            case .server(let statusCode, let data):
                XCTAssertEqual(statusCode, 500)
                XCTAssertEqual(data, expectedData)
            default:
                XCTFail("Expected .server error, got \(error)")
            }
        } catch {
            XCTFail("Expected NetworkError, got \(error)")
        }
    }

    func test_request_whenDecodingFails_throwsDecodingError() async throws {
        // given
        let sut = makeSUT()
        let endpoint = Endpoint(
            baseURL: try makeURL("https://example.com"),
            path: "/users/me",
            method: .get
        )

        StubURLProtocol.setRequestHandler { request in
            let response = try makeHTTPURLResponse(
                url: try XCTUnwrap(request.url),
                statusCode: 200
            )
            return (response, SampleResponseData.invalidJSON)
        }

        // when / then
        do {
            let _: UserResponseFixture = try await sut.request(endpoint, as: UserResponseFixture.self)
            XCTFail("Expected decoding error, but succeeded.")
        } catch let error as NetworkError {
            switch error {
            case .decoding:
                XCTAssertTrue(true)
            default:
                XCTFail("Expected .decoding error, got \(error)")
            }
        } catch {
            XCTFail("Expected NetworkError, got \(error)")
        }
    }

    func test_request_whenTransportErrorOccurs_throwsTransportError() async throws {
        // given
        let sut = makeSUT()
        let endpoint = Endpoint(
            baseURL: try makeURL("https://example.com"),
            path: "/users/me",
            method: .get
        )

        StubURLProtocol.setRequestHandler { _ in
            throw URLError(.notConnectedToInternet)
        }

        // when / then
        do {
            let _ = try await sut.request(endpoint)
            XCTFail("Expected transport error, but succeeded.")
        } catch let error as NetworkError {
            switch error {
            case .transport:
                XCTAssertTrue(true)
            default:
                XCTFail("Expected .transport error, got \(error)")
            }
        } catch {
            XCTFail("Expected NetworkError, got \(error)")
        }
    }

    func test_request_whenStatusCodeIs401_throwsUnauthorized() async throws {
        // given
        let sut = makeSUT()
        let endpoint = Endpoint(
            baseURL: try makeURL("https://example.com"),
            path: "/protected",
            method: .get
        )

        StubURLProtocol.setRequestHandler { request in
            let response = try makeHTTPURLResponse(
                url: try XCTUnwrap(request.url),
                statusCode: 401
            )
            return (response, Data())
        }

        // when / then
        do {
            let _: UserResponseFixture = try await sut.request(endpoint, as: UserResponseFixture.self)
            XCTFail("Expected .unauthorized")
        } catch let error as NetworkError {
            switch error {
            case .unauthorized:
                XCTAssertTrue(true)
            default:
                XCTFail("Expected .unauthorized, got \(error)")
            }
        }
    }

    func test_request_whenStatusCodeIs403_throwsForbidden() async throws {
        // given
        let sut = makeSUT()
        let endpoint = Endpoint(
            baseURL: try makeURL("https://example.com"),
            path: "/protected",
            method: .get
        )

        StubURLProtocol.setRequestHandler { request in
            let response = try makeHTTPURLResponse(
                url: try XCTUnwrap(request.url),
                statusCode: 403
            )
            return (response, Data())
        }

        // when / then
        do {
            let _: UserResponseFixture = try await sut.request(endpoint, as: UserResponseFixture.self)
            XCTFail("Expected .forbidden")
        } catch let error as NetworkError {
            switch error {
            case .forbidden:
                XCTAssertTrue(true)
            default:
                XCTFail("Expected .forbidden, got \(error)")
            }
        }
    }

    func test_request_whenResponseDataIsEmpty_throwsEmptyResponse() async throws {
        // given
        let sut = makeSUT()
        let endpoint = Endpoint(
            baseURL: try makeURL("https://example.com"),
            path: "/users/me",
            method: .get
        )

        StubURLProtocol.setRequestHandler { request in
            let response = try makeHTTPURLResponse(
                url: try XCTUnwrap(request.url),
                statusCode: 200
            )
            return (response, Data())
        }

        // when / then
        do {
            let _: UserResponseFixture = try await sut.request(endpoint, as: UserResponseFixture.self)
            XCTFail("Expected .emptyResponse")
        } catch let error as NetworkError {
            switch error {
            case .emptyResponse:
                XCTAssertTrue(true)
            default:
                XCTFail("Expected .emptyResponse, got \(error)")
            }
        }
    }

    func test_request_whenTransportErrorIsTimeout_throwsTimeout() async throws {
        // given
        let sut = makeSUT()
        let endpoint = Endpoint(
            baseURL: try makeURL("https://example.com"),
            path: "/users/me",
            method: .get
        )

        StubURLProtocol.setRequestHandler { _ in
            throw URLError(.timedOut)
        }

        // when / then
        do {
            let _ = try await sut.request(endpoint)
            XCTFail("Expected .timeout")
        } catch let error as NetworkError {
            switch error {
            case .timeout:
                XCTAssertTrue(true)
            default:
                XCTFail("Expected .timeout, got \(error)")
            }
        }
    }
}

// MARK: - Helpers

private extension URLSessionNetworkClientTests {
    func makeSUT(
        token: String? = nil,
        defaultHeaders: [String: String] = [:]
    ) -> URLSessionNetworkClient {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]

        let session = URLSession(configuration: configuration)

        let requestBuilder = NetworkRequestBuilder(
            authorizationProvider: StaticBearerTokenProvider(token: token),
            configuration: NetworkConfiguration(
                timeoutInterval: 10,
                cachePolicy: .reloadIgnoringLocalCacheData,
                defaultHeaders: defaultHeaders
            )
        )

        return URLSessionNetworkClient(
            session: session,
            requestBuilder: requestBuilder
        )
    }
}
