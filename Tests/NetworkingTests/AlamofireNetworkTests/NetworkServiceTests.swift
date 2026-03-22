//
//  NetworkServiceTests.swift
//  CoreNetwork
//
//  Created by jch on 6/29/25.
//

import Foundation
import XCTest
import Combine
@testable import CoreNetwork

private struct DummyResponse: Decodable, Sendable {
    
}

final class NetworkServiceTests: XCTestCase {
    private var testNetworkService: NetworkService!
    
    private var testCancellables: Set<AnyCancellable>!

    override func setUpWithError() throws {
        testNetworkService = NetworkService()
        
        testCancellables = []
    }

    override func tearDownWithError() throws {
        testNetworkService = nil
        
        testCancellables = nil
    }

    func testNetworkServiceRequestFail() {
        let testExpectation = XCTestExpectation(description: "(요청 실패 유도) 요청 실패")

        testNetworkService
            .request(.invalidRequest, type: DummyResponse.self)
            .sink(
                receiveCompletion: { testCompletion in
                    switch testCompletion {
                    case .failure:
                        testExpectation.fulfill()
                    case .finished:
                        XCTFail("(요청 실패 유도) 요청이 성공적으로 끝나서는 안 됩니다.")
                    }
                },
                receiveValue: { _ in
                    XCTFail("(요청 실패 유도) 응답이 와서는 안됩니다.")
                }
            )
            .store(in: &testCancellables)
        
        wait(for: [testExpectation], timeout: 5.0)
    }

    func testSearchDetailListEndpointURLRequest() {
        let testKeyword = "테스트"
        let testEndpoint = APIEndpoint.searchDetailList(searchKeyword: testKeyword)
        let testRequest = testEndpoint.urlRequest

        guard testRequest.url != nil else {
            XCTFail("유효하지 않은 URL입니다")
            return
        }
        
        guard let testUrl = testRequest.url,
              let testComponents = URLComponents(url: testUrl, resolvingAgainstBaseURL: false),
              let testQueryItems = testComponents.queryItems else {
            return XCTFail("URL 또는 쿼리 파싱 실패")
        }
        
        XCTAssertEqual(testQueryItems.first(where: { $0.name == "term" })?.value, testKeyword)
        XCTAssertEqual(testQueryItems.first(where: { $0.name == "media" })?.value, "software")
        XCTAssertEqual(testQueryItems.first(where: { $0.name == "country" })?.value, "KR")
        XCTAssertEqual(testRequest.httpMethod, "GET")
    }
}
