//
//  AlamofireNetworkClientTests.swift
//  Networking
//
//  Created by jch on 3/22/26.
//

import Foundation
import XCTest
import Alamofire
@testable import Networking

/// `AlamofireNetworkClient`의 요청 실행, 응답 디코딩, 에러 매핑을 검증합니다.
final class AlamofireNetworkClientTests: XCTestCase {

    // MARK: - Setup

    override func tearDownWithError() throws {
        StubURLProtocol.removeHandler()
        try super.tearDownWithError()
    }

    // MARK: - Tests

    func test_request_whenResponseIsSuccessful_returnsDecodedModel() async throws {
        // given
        let sut = makeSUT(token: "test-token")
        let endpoint = Endpoint(
            baseURL: try makeURL("https://example.com"),
            path: "/users/me",
            method: .get,
            requiresAuthorization: true
        )
        let expectedDTO = UserResponseFixture(id: 1, name: "jch")

        StubURLProtocol.setRequestHandler { request in
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer test-token")

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

    func test_request_whenStatusCodeIsNot2xx_throwsHTTPError() async throws {
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
            XCTFail("Expected .http error, but succeeded.")
        } catch let error as NetworkError {
            switch error {
            case .http(let httpError):
                XCTAssertEqual(httpError.statusCode, 500)
                XCTAssertEqual(httpError.data, expectedData)
                XCTAssertNil(httpError.payload)
            default:
                XCTFail("Expected .http error, got \(error)")
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
            path: "/health",
            method: .get
        )

        StubURLProtocol.setRequestHandler { _ in
            throw URLError(.notConnectedToInternet)
        }

        // when / then
        do {
            let _ = try await sut.request(endpoint)
            XCTFail("Expected .transport error, but succeeded.")
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
            XCTFail("Expected .decoding error, but succeeded.")
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

    func test_request_whenStatusCodeIs401_throwsHTTPErrorWithPayload() async throws {
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
            return (response, SampleResponseData.invalidCredentialsError)
        }

        // when / then
        do {
            let _: UserResponseFixture = try await sut.request(endpoint, as: UserResponseFixture.self)
            XCTFail("Expected .http")
        } catch let error as NetworkError {
            switch error {
            case .http(let httpError):
                XCTAssertEqual(httpError.statusCode, 401)
                XCTAssertEqual(httpError.payload?.code, "AUTH_INVALID_CREDENTIALS")
                XCTAssertEqual(httpError.data, SampleResponseData.invalidCredentialsError)
            default:
                XCTFail("Expected .http, got \(error)")
            }
        }
    }

    func test_request_whenStatusCodeIs403_throwsHTTPErrorWithPayload() async throws {
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
            return (response, SampleResponseData.inactiveUserError)
        }

        // when / then
        do {
            let _: UserResponseFixture = try await sut.request(endpoint, as: UserResponseFixture.self)
            XCTFail("Expected .http")
        } catch let error as NetworkError {
            switch error {
            case .http(let httpError):
                XCTAssertEqual(httpError.statusCode, 403)
                XCTAssertEqual(httpError.payload?.code, "AUTH_INACTIVE_USER")
                XCTAssertEqual(httpError.data, SampleResponseData.inactiveUserError)
            default:
                XCTFail("Expected .http, got \(error)")
            }
        }
    }

    func test_request_whenEmptyResponseIsAllowed_returnsEmptyResponse() async throws {
        // given
        let sut = makeSUT()
        let endpoint = Endpoint(
            baseURL: try makeURL("https://example.com"),
            path: "/logout",
            method: .post,
            allowsEmptyResponse: true
        )

        StubURLProtocol.setRequestHandler { request in
            let response = try makeHTTPURLResponse(
                url: try XCTUnwrap(request.url),
                statusCode: 204
            )
            return (response, Data())
        }

        // when
        let result = try await sut.request(endpoint, as: EmptyResponse.self)

        // then
        XCTAssertNotNil(result)
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
}

// MARK: - Helpers

private extension AlamofireNetworkClientTests {
    func makeSUT(token: String? = nil) -> AlamofireNetworkClient {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]

        let session = Session(configuration: configuration)

        let requestBuilder = NetworkRequestBuilder(
            authorizationProvider: StaticBearerTokenProvider(token: token),
            configuration: NetworkConfiguration.default
        )

        return AlamofireNetworkClient(
            session: session,
            requestBuilder: requestBuilder
        )
    }
}
