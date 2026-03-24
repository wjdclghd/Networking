//
//  NetworkEvent.swift
//  Networking
//
//  Created by jch on 3/23/26.
//

import Foundation

public enum NetworkEvent: Sendable {
    case requestStarted(id: UUID, request: URLRequest)
    case requestFinished(
        id: UUID,
        request: URLRequest,
        response: HTTPURLResponse?,
        data: Data?,
        duration: TimeInterval
    )
    case requestFailed(
        id: UUID,
        request: URLRequest,
        error: Error,
        duration: TimeInterval
    )
}
