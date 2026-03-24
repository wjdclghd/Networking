//
//  NetworkEventLogger.swift
//  Networking
//
//  Created by jch on 3/23/26.
//

import Foundation

public protocol NetworkEventLogger: Sendable {
    func log(_ event: NetworkEvent)
}
