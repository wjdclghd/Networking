//
//  MockURLProtocol.swift
//  Networking
//
//  Created by jch on 3/22/26.
//

import Foundation
import XCTest

final class MockURLProtocol: URLProtocol, @unchecked Sendable {
    typealias RequestHandler = (URLRequest) throws -> (HTTPURLResponse, Data)

    private static let lock = NSLock()
    private static var requestHandler: RequestHandler?

    static func setRequestHandler(_ handler: @escaping RequestHandler) {
        lock.lock()
        defer { lock.unlock() }
        requestHandler = handler
    }

    static func removeHandler() {
        lock.lock()
        defer { lock.unlock() }
        requestHandler = nil
    }

    private static func currentHandler() -> RequestHandler? {
        lock.lock()
        defer { lock.unlock() }
        return requestHandler
    }

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let handler = Self.currentHandler() else {
            client?.urlProtocol(
                self,
                didFailWithError: URLError(.badServerResponse)
            )
            return
        }

        do {
            let (response, data) = try handler(request)

            client?.urlProtocol(
                self,
                didReceive: response,
                cacheStoragePolicy: .notAllowed
            )
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() { }
}
