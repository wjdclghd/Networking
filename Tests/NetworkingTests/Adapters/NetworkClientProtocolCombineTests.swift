//
//  NetworkClientProtocolCombineTests.swift
//  Networking
//
//  Created by jch on 3/22/26.
//

import Foundation
import XCTest
import Combine
@testable import Networking

/// `NetworkClientProtocol`의 Combine publisher 확장 메서드를 검증합니다.
final class NetworkClientProtocolCombineTests: XCTestCase {

    // MARK: - Properties

    private var cancellables: Set<AnyCancellable>!

    // MARK: - Setup

    override func tearDownWithError() throws {
        cancellables = nil
        try super.tearDownWithError()
    }

    // MARK: - Tests

    func test_publisherData_whenAsyncRequestSucceeds_emitsData() throws {
        // given
        let sut = StubNetworkClient()
        let expectedData = Data("success".utf8)
        sut.dataResult = .success(expectedData)
        cancellables = []

        let endpoint = Endpoint(
            baseURL: try makeURL("https://example.com"),
            path: "/health",
            method: .get
        )
        let expectation = expectation(description: "publisher emits data")

        // when
        sut.publisher(endpoint)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Expected success, got failure: \(error)")
                    }
                },
                receiveValue: { value in
                    // then
                    XCTAssertEqual(value, expectedData)
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1.0)
    }

    func test_publisherData_whenAsyncRequestFails_emitsFailure() throws {
        // given
        let sut = StubNetworkClient()
        sut.dataResult = .failure(NetworkError.invalidRequest)
        cancellables = []

        let endpoint = Endpoint(
            baseURL: try makeURL("https://example.com"),
            path: "/health",
            method: .get
        )
        let expectation = expectation(description: "publisher emits failure")

        // when
        sut.publisher(endpoint)
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        XCTFail("Expected failure, got finished")
                    case .failure(let error):
                        // then
                        switch error {
                        case .invalidRequest:
                            XCTAssertTrue(true)
                            expectation.fulfill()
                        default:
                            XCTFail("Expected .invalidRequest, got \(error)")
                        }
                    }
                },
                receiveValue: { _ in
                    XCTFail("Expected no value")
                }
            )
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1.0)
    }

    func test_publisherData_whenAsyncRequestFailsWithHTTPError_emitsHTTPFailure() throws {
        // given
        let sut = StubNetworkClient()
        let payload = NetworkErrorPayload(
            code: "RATE_LIMIT_EXCEEDED",
            message: "요청 횟수가 너무 많습니다. 잠시 후 다시 시도해 주세요.",
            details: [],
            timestamp: "2026-05-10T09:00:00Z"
        )
        sut.dataResult = .failure(
            NetworkError.http(
                NetworkHTTPError(
                    statusCode: 429,
                    payload: payload,
                    data: SampleResponseData.rateLimitExceededError
                )
            )
        )
        cancellables = []

        let endpoint = Endpoint(
            baseURL: try makeURL("https://example.com"),
            path: "/api/auth/login",
            method: .post
        )
        let expectation = expectation(description: "publisher emits HTTP failure")

        // when
        sut.publisher(endpoint)
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        XCTFail("Expected failure, got finished")
                    case .failure(let error):
                        // then
                        switch error {
                        case .http(let httpError):
                            XCTAssertEqual(httpError.statusCode, 429)
                            XCTAssertEqual(httpError.payload?.code, "RATE_LIMIT_EXCEEDED")
                            expectation.fulfill()
                        default:
                            XCTFail("Expected .http, got \(error)")
                        }
                    }
                },
                receiveValue: { _ in
                    XCTFail("Expected no value")
                }
            )
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1.0)
    }

    func test_publisherDecodable_whenAsyncRequestSucceeds_emitsDecodedValue() throws {
        // given
        let sut = StubNetworkClient()
        let expectedValue = UserResponseFixture(id: 1, name: "jch")
        sut.decodedResult = .success(expectedValue)
        cancellables = []

        let endpoint = Endpoint(
            baseURL: try makeURL("https://example.com"),
            path: "/users/me",
            method: .get
        )
        let expectation = expectation(description: "publisher emits decoded value")

        // when
        sut.publisher(endpoint, as: UserResponseFixture.self)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Expected success, got failure: \(error)")
                    }
                },
                receiveValue: { value in
                    // then
                    XCTAssertEqual(value, expectedValue)
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1.0)
    }

    func test_publisherDecodable_whenAsyncRequestFails_emitsDecodingFailure() throws {
        // given
        let sut = StubNetworkClient()
        sut.decodedResult = .failure(NetworkError.decoding(URLError(.cannotDecodeContentData)))
        cancellables = []

        let endpoint = Endpoint(
            baseURL: try makeURL("https://example.com"),
            path: "/users/me",
            method: .get
        )
        let expectation = expectation(description: "publisher emits decode failure")

        // when
        sut.publisher(endpoint, as: UserResponseFixture.self)
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        XCTFail("Expected failure, got finished")
                    case .failure(let error):
                        // then
                        switch error {
                        case .decoding:
                            XCTAssertTrue(true)
                            expectation.fulfill()
                        default:
                            XCTFail("Expected .decoding, got \(error)")
                        }
                    }
                },
                receiveValue: { _ in
                    XCTFail("Expected no value")
                }
            )
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1.0)
    }
}
