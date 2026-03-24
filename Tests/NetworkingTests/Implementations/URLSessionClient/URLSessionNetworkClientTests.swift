//
//  URLSessionNetworkClientTests.swift
//  Networking
//
//  Created by jch on 3/22/26.
//

import Foundation
import XCTest
@testable import Networking

final class URLSessionNetworkClientTests: XCTestCase {
    override func tearDown() {
        super.tearDown()
        MockURLProtocol.removeHandler()
    }

    func test_request_whenResponseIsSuccessful_returnsDecodedModel() async throws {
        let sut = makeSUT(
            token: "test-token",
            defaultHeaders: ["X-App-Version": "1.0.0"]
        )

        let endpoint = Endpoint(
            baseURL: try makeURL("https://example.com"),
            path: "/users/me",
            method: .get,
            queryItems: [
                URLQueryItem(name: "lang", value: "ko")
            ],
            task: .plain,
            requiresAuthorization: true
        )

        let responseDTO = MockUserResponseDTO(
            id: 1,
            name: "jch"
        )

        let responseData = SampleResponseData.validUser

        MockURLProtocol.setRequestHandler { request in
            XCTAssertEqual(request.httpMethod, "GET")
            XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer test-token")
            XCTAssertEqual(request.value(forHTTPHeaderField: "X-App-Version"), "1.0.0")
            XCTAssertEqual(request.url?.absoluteString, "https://example.com/users/me?lang=ko")

            let response = try makeHTTPURLResponse(
                url: try XCTUnwrap(request.url),
                statusCode: 200
            )

            return (response, responseData)
        }

        let result = try await sut.request(endpoint, as: MockUserResponseDTO.self)

        XCTAssertEqual(result, responseDTO)
    }

    func test_request_whenResponseIsSuccessful_returnsRawData() async throws {
        let sut = makeSUT()

        let endpoint = Endpoint(
            baseURL: try makeURL("https://example.com"),
            path: "/health",
            method: .get
        )

        let expectedData = Data("ok".utf8)

        MockURLProtocol.setRequestHandler { request in
            let response = try makeHTTPURLResponse(
                url: try XCTUnwrap(request.url),
                statusCode: 200
            )

            return (response, expectedData)
        }

        let result = try await sut.request(endpoint)

        XCTAssertEqual(result, expectedData)
    }

    func test_request_whenStatusCodeIsNot2xx_throwsServerError() async throws {
        let sut = makeSUT()

        let endpoint = Endpoint(
            baseURL: try makeURL("https://example.com"),
            path: "/users/me",
            method: .get
        )

        let expectedData = Data("server-error".utf8)

        MockURLProtocol.setRequestHandler { request in
            let response = try makeHTTPURLResponse(
                url: try XCTUnwrap(request.url),
                statusCode: 500
            )

            return (response, expectedData)
        }

        do {
            let _: MockUserResponseDTO = try await sut.request(endpoint, as: MockUserResponseDTO.self)
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
        let sut = makeSUT()

        let endpoint = Endpoint(
            baseURL: try makeURL("https://example.com"),
            path: "/users/me",
            method: .get
        )

        let invalidJSONData = SampleResponseData.invalidJSON

        MockURLProtocol.setRequestHandler { request in
            let response = try makeHTTPURLResponse(
                url: try XCTUnwrap(request.url),
                statusCode: 200
            )

            return (response, invalidJSONData)
        }

        do {
            let _: MockUserResponseDTO = try await sut.request(endpoint, as: MockUserResponseDTO.self)
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
        let sut = makeSUT()

        let endpoint = Endpoint(
            baseURL: try makeURL("https://example.com"),
            path: "/users/me",
            method: .get
        )

        MockURLProtocol.setRequestHandler { _ in
            throw URLError(.notConnectedToInternet)
        }

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
        let sut = makeSUT()

        let endpoint = Endpoint(
            baseURL: try makeURL("https://example.com"),
            path: "/protected",
            method: .get
        )

        MockURLProtocol.setRequestHandler { request in
            let response = try makeHTTPURLResponse(
                url: try XCTUnwrap(request.url),
                statusCode: 401
            )

            return (response, Data())
        }

        do {
            let _: MockUserResponseDTO = try await sut.request(endpoint, as: MockUserResponseDTO.self)
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
        let sut = makeSUT()

        let endpoint = Endpoint(
            baseURL: try makeURL("https://example.com"),
            path: "/protected",
            method: .get
        )

        MockURLProtocol.setRequestHandler { request in
            let response = try makeHTTPURLResponse(
                url: try XCTUnwrap(request.url),
                statusCode: 403
            )

            return (response, Data())
        }

        do {
            let _: MockUserResponseDTO = try await sut.request(endpoint, as: MockUserResponseDTO.self)
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
        let sut = makeSUT()

        let endpoint = Endpoint(
            baseURL: try makeURL("https://example.com"),
            path: "/users/me",
            method: .get
        )

        MockURLProtocol.setRequestHandler { request in
            let response = try makeHTTPURLResponse(
                url: try XCTUnwrap(request.url),
                statusCode: 200
            )

            return (response, Data())
        }

        do {
            let _: MockUserResponseDTO = try await sut.request(endpoint, as: MockUserResponseDTO.self)
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
        let sut = makeSUT()

        let endpoint = Endpoint(
            baseURL: try makeURL("https://example.com"),
            path: "/users/me",
            method: .get
        )

        MockURLProtocol.setRequestHandler { _ in
            throw URLError(.timedOut)
        }

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

private extension URLSessionNetworkClientTests {
    func makeSUT(
        token: String? = nil,
        defaultHeaders: [String: String] = [:]
    ) -> URLSessionNetworkClient {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]

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
