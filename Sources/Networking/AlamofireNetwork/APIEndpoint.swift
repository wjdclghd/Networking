//
//  APIEndpoint.swift
//  CoreNetwork
//
//  Created by jch on 6/29/25.
//

import Foundation

public enum HTTPMethodType: String {
    case get = "GET"
    case post = "POST"
}

public enum APIEndpoint {
    case invalidRequest
    case searchDetailList(searchKeyword: String)
    case chatGPTSearch(searchKeyword: String)
    
    public var requiresAuth: Bool {
        switch self {
        case .chatGPTSearch:
            return true
        default:
            return false
        }
    }
    
    public var baseURL: String {
        switch self {
        case .invalidRequest:
            return "https://this.should.fail.example"
        case .searchDetailList:
            return "https://itunes.apple.com"
        case .chatGPTSearch:
            return "https://api.openai.com"
        }
    }
    
    public var path: String {
        switch self {
        case .invalidRequest:
            return "/invalid"
        case .searchDetailList:
            return "/search"
        case .chatGPTSearch:
            return "/v1/chat/completions"
        }
    }
    
    public var method: HTTPMethodType {
        switch self {
        case .invalidRequest, .searchDetailList:
            return .get
        case .chatGPTSearch:
            return .post
        }
    }
    
    public var queryItems: [URLQueryItem]? {
        switch self {
        case .invalidRequest:
            return nil
        case .searchDetailList(let searchKeyword):
            return [
                URLQueryItem(name: "term", value: searchKeyword),
                URLQueryItem(name: "media", value: "software"),
                URLQueryItem(name: "country", value: "KR")
            ]
        case .chatGPTSearch:
            return nil
        }
    }
    
    public var urlRequest: URLRequest {
        switch self {
        case .invalidRequest, .searchDetailList:
            var components = URLComponents(string: baseURL + path)!
            components.queryItems = queryItems
            
            var request = URLRequest(url: components.url!)
            request.httpMethod = method.rawValue
            
            return request
        case .chatGPTSearch(let searchKeyword):
            let url = URL(string: baseURL + path)!
            var request = URLRequest(url: url)
            request.httpMethod = method.rawValue
            
            let body: [String: Any] = [
                "model": "gpt-3.5-turbo",
                "messages": [
                    ["role": "user", "content": searchKeyword]
                ],
                "temperature": 0.7
            ]
            
            request.httpBody = try? JSONSerialization.data(withJSONObject: body)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            return request
        }
    }
}
