//
//  NetworkRetryPolicy.swift
//  Networking
//
//  Created by jch on 3/23/26.
//

import Foundation

public protocol NetworkRetryPolicy: Sendable {
    /// Return delay (seconds) to retry, or nil to stop retrying.
    func retryDelay(
        for request: URLRequest,
        error: Error,
        attempt: Int
    ) -> TimeInterval?
}
