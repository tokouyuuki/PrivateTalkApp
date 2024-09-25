//
//  NetworkService.swift
//  PrivateTalkApp
//
//  Created by 都甲裕希 on 2024/08/27.
//

import Foundation

// MARK: - ネットワーク通信
struct NetworkService {
    
    func fetch<T: Decodable>(urlString: String, decodeTo type: T.Type) async throws -> T {
        guard let url = URL(string: urlString) else {
            throw NetworkError.badUrlError
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            // レスポンスが返ってきているかのチェック
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.noResponse
            }
            
            // レスポンスステータスコードが200番台以外の場合
            if httpResponse.statusCode != 200 {
                if [400, 404, 500, 502, 503, 504].contains(httpResponse.statusCode) {
                    throw NetworkError.httpResponseError(statusCode: httpResponse.statusCode)
                } else {
                    throw NetworkError.httpResponseError(statusCode: nil)
                }
            }
            
            let decodeData = try JSONDecoder().decode(T.self, from: data)
            return decodeData
            
        } catch let urlError as URLError {
            throw NetworkError.urlError(urlError.code)
        } catch let decodingError as DecodingError {
            throw NetworkError.decodingError(decodingError)
        }
    }
}

// MARK: - ネットワーク通信エラーのenum
enum NetworkError: LocalizedError {
    case badUrlError
    case noResponse
    case httpResponseError(statusCode: Int?)
    case urlError(URLError.Code)
    case decodingError(DecodingError)
    
    var errorDescription: String {
        switch self {
        case .badUrlError:
            return NSLocalizedString("bad_url_error", comment: String.empty)
        case .noResponse:
            return NSLocalizedString("no_response", comment: String.empty)
        case .httpResponseError(statusCode: let statusCode):
            guard let statusCode = statusCode else {
                return NSLocalizedString("unexpected_error", comment: String.empty)
            }
            return NSLocalizedString("response_error_\(statusCode)", comment: String.empty)
        case .urlError(let urlErrorCode):
            if urlErrorCode == .notConnectedToInternet {
                return NSLocalizedString("no_connected_to_internet_error", comment: String.empty)
            } else if urlErrorCode == .timedOut {
                return NSLocalizedString("timeout_error", comment: String.empty)
            } else if urlErrorCode == .cannotFindHost {
                return NSLocalizedString("cannot_find_host_error", comment: String.empty)
            } else if urlErrorCode == .cannotConnectToHost {
                return NSLocalizedString("cannot_connect_to_host_error", comment: String.empty)
            } else if urlErrorCode == .unsupportedURL {
                return NSLocalizedString("unsupported_url_error", comment: String.empty)
            } else if urlErrorCode == .networkConnectionLost {
                return NSLocalizedString("network_connection_lost_error", comment: String.empty)
            } else {
                return NSLocalizedString("unexpected_error", comment: String.empty)
            }
        case .decodingError(_):
            return NSLocalizedString("unexpected_error", comment: String.empty)
        }
    }
}
