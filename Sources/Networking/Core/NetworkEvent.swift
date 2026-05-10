//
//  NetworkEvent.swift
//  Networking
//
//  Created by jch on 3/23/26.
//

import Foundation

/// 네트워크 요청 생명주기에서 발생하는 logging event입니다.
public enum NetworkEvent: Sendable {
    /// 요청이 시작되었음을 나타냅니다.
    case requestStarted(id: UUID, request: URLRequest)
    /// 요청이 성공적으로 완료되었음을 나타냅니다.
    case requestFinished(
        id: UUID,
        request: URLRequest,
        response: HTTPURLResponse?,
        data: Data?,
        duration: TimeInterval
    )
    /// 요청이 실패했음을 나타냅니다.
    case requestFailed(
        id: UUID,
        request: URLRequest,
        error: Error,
        duration: TimeInterval
    )
}
