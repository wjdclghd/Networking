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

final class NetworkClientProtocolCombineTests: XCTestCase {
    private var cancellables: Set<AnyCancellable> = []

    override func tearDown() {
        cancellables.removeAll()
        super.tearDown()
    }

    func test_publisherData_whenAsyncRequestSucceeds_emitsData() throws {
        let sut = MockNetworkClient()
        let expectedData = Data("success".utf8)
        sut.dataResult = .success(expectedData)

        let endpoint = Endpoint(
            baseURL: try makeURL("https://example.com"),
            path: "/health",
            method: .get
        )

        let expectation = expectation(description: "publisher emits data")

        sut.publisher(endpoint)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Expected success, got failure: \(error)")
                    }
                },
                receiveValue: { value in
                    XCTAssertEqual(value, expectedData)
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1.0)
    }

    func test_publisherData_whenAsyncRequestFails_emitsFailure() throws {
        let sut = MockNetworkClient()
        sut.dataResult = .failure(NetworkError.invalidRequest)

        let endpoint = Endpoint(
            baseURL: try makeURL("https://example.com"),
            path: "/health",
            method: .get
        )

        let expectation = expectation(description: "publisher emits failure")

        sut.publisher(endpoint)
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        XCTFail("Expected failure, got finished")
                    case .failure(let error):
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

    func test_publisherDecodable_whenAsyncRequestSucceeds_emitsDecodedValue() throws {
        let sut = MockNetworkClient()
        let expectedValue = MockUserResponseDTO(id: 1, name: "jch")
        sut.decodedResult = .success(expectedValue)

        let endpoint = Endpoint(
            baseURL: try makeURL("https://example.com"),
            path: "/users/me",
            method: .get
        )

        let expectation = expectation(description: "publisher emits decoded value")

        sut.publisher(endpoint, as: MockUserResponseDTO.self)
            .sink(
                receiveCompletion: { completion in
                    if case .failure(let error) = completion {
                        XCTFail("Expected success, got failure: \(error)")
                    }
                },
                receiveValue: { value in
                    XCTAssertEqual(value, expectedValue)
                    expectation.fulfill()
                }
            )
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1.0)
    }

    func test_publisherDecodable_whenAsyncRequestFails_emitsFailure() throws {
        let sut = MockNetworkClient()
        sut.decodedResult = .failure(NetworkError.decoding(URLError(.cannotDecodeContentData)))

        let endpoint = Endpoint(
            baseURL: try makeURL("https://example.com"),
            path: "/users/me",
            method: .get
        )

        let expectation = expectation(description: "publisher emits decode failure")

        sut.publisher(endpoint, as: MockUserResponseDTO.self)
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        XCTFail("Expected failure, got finished")
                    case .failure(let error):
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
