//
//  NetworkEventLogger.swift
//  Networking
//
//  Created by jch on 3/23/26.
//

import Foundation

/// 네트워크 요청 event를 기록합니다.
public protocol NetworkEventLogger: Sendable {
    /// 전달받은 네트워크 event를 기록합니다.
    ///
    /// - Parameter event: 기록할 요청 event입니다.
    func log(_ event: NetworkEvent)
}
