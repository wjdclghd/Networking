//
//  NetworkConfiguration.swift
//  Networking
//
//  Created by jch on 3/22/26.
//

import Foundation

/// 네트워크 요청 생성과 실행에 사용하는 공통 설정입니다.
public struct NetworkConfiguration: Sendable {
    /// 요청 제한 시간입니다.
    public let timeoutInterval: TimeInterval
    /// URLRequest에 적용할 캐시 정책입니다.
    public let cachePolicy: URLRequest.CachePolicy
    /// 모든 요청에 기본으로 적용할 header입니다.
    public let defaultHeaders: [String: String]
    /// 요청 이벤트를 기록할 logger입니다.
    public let logger: NetworkEventLogger?
    /// 실패한 요청의 재시도 여부와 지연 시간을 결정하는 정책입니다.
    public let retryPolicy: NetworkRetryPolicy?

    /// 네트워크 설정을 생성합니다.
    ///
    /// - Parameters:
    ///   - timeoutInterval: 요청 제한 시간입니다.
    ///   - cachePolicy: URLRequest에 적용할 캐시 정책입니다.
    ///   - defaultHeaders: 모든 요청에 기본으로 적용할 header입니다.
    ///   - logger: 요청 이벤트를 기록할 logger입니다.
    ///   - retryPolicy: 실패한 요청의 재시도 여부와 지연 시간을 결정하는 정책입니다.
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

    /// 기본 네트워크 설정입니다.
    public static let `default` = NetworkConfiguration()
}
