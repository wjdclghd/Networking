//
//  NetworkRetryPolicy.swift
//  Networking
//
//  Created by jch on 3/23/26.
//

import Foundation

/// 실패한 네트워크 요청의 재시도 여부와 지연 시간을 결정합니다.
public protocol NetworkRetryPolicy: Sendable {
    /// 요청을 재시도할 지연 시간을 반환합니다.
    ///
    /// - Parameters:
    ///   - request: 실패한 URLRequest입니다.
    ///   - error: 요청 실패 오류입니다.
    ///   - attempt: 현재까지 수행한 재시도 횟수입니다.
    /// - Returns: 재시도 전 대기할 초 단위 시간입니다. `nil`이면 재시도하지 않습니다.
    func retryDelay(
        for request: URLRequest,
        error: Error,
        attempt: Int
    ) -> TimeInterval?
}
