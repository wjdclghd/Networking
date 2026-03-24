//
//  NetworkConfiguration.swift
//  Networking
//
//  Created by jch on 3/22/26.
//

import Foundation

public struct NetworkConfiguration: Sendable {
    public let timeoutInterval: TimeInterval
    public let cachePolicy: URLRequest.CachePolicy
    public let defaultHeaders: [String: String]
    public let logger: NetworkEventLogger?
    public let retryPolicy: NetworkRetryPolicy?

    public init(
        timeoutInterval: TimeInterval = 30,
        cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy,
        defaultHeaders: [String: String] = [:],
        logger: NetworkEventLogger? = nil,
        retryPolicy: NetworkRetryPolicy? = nil
    ) {
        self.timeoutInterval = timeoutInterval
        self.cachePolicy = cachePolicy
        self.defaultHeaders = defaultHeaders
        self.logger = logger
        self.retryPolicy = retryPolicy
    }

    public static let `default` = NetworkConfiguration()
}
