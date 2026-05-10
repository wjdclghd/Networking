//
//  FormURLEncodedSerializer.swift
//  Networking
//
//  Created by jch on 3/22/26.
//

import Foundation

/// form-urlencoded body 문자열을 생성합니다.
public struct FormURLEncodedSerializer {
    /// 파라미터를 `application/x-www-form-urlencoded` 형식으로 인코딩합니다.
    ///
    /// - Parameter parameters: body에 포함할 key-value 파라미터입니다.
    /// - Returns: form-urlencoded 형식의 문자열입니다.
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
