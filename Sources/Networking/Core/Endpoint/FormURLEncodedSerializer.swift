//
//  FormURLEncodedSerializer.swift
//  Networking
//
//  Created by jch on 3/22/26.
//

import Foundation

public struct FormURLEncodedSerializer {
    public static func encode(_ parameters: [String: String]) -> String {
        parameters
            .map { key, value in
                "\(escape(key))=\(escape(value))"
            }
            .joined(separator: "&")
    }

    private static func escape(_ string: String) -> String {
        let allowedCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-._~"))
        let encoded = string.addingPercentEncoding(withAllowedCharacters: allowedCharacters) ?? string
        return encoded.replacingOccurrences(of: "%20", with: "+")
    }
}
