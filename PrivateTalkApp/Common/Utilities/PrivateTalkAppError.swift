//
//  PrivateTalkAppError.swift
//  PrivateTalkApp
//
//  Created by 都甲裕希 on 2024/10/16.
//

import Foundation

// MARK: - アプリ全体で扱う汎用エラー
enum PrivateTalkAppError: LocalizedError {
    
    private struct Constants {
        static let UNEXPECTED_ERROR_MESSAGE = NSLocalizedString("unexpected_error", comment: String.empty)
    }
    
    // ネットワーク通信エラー
    case networkError(NetworkError)
    // カレンダーイベントのエラー
    case eventError(EventError)
    // 予期せぬエラー
    case unexpected
    
    var errorDescription: String {
        switch self {
        case .networkError(let networkError):
            return networkError.errorDescription
        case .eventError(let eventError):
            return eventError.errorDescription
        case .unexpected:
            return Constants.UNEXPECTED_ERROR_MESSAGE
        }
    }
}

// MARK: - ネットワーク通信エラー
enum NetworkError: LocalizedError {
    
    private struct Constants {
        static let BAD_URL_ERROR_MESSAGE = NSLocalizedString("bad_url_error", comment: String.empty)
        static let NO_RESPONSE_ERROR_MESSAGE = NSLocalizedString("no_response", comment: String.empty)
        static let HTTP_RESPONSE_ERROR_KEY = "response_error_"
        static let NO_CONNECTED_TO_INTERNET_ERROR_MESSAGE = NSLocalizedString("no_connected_to_internet_error", comment: String.empty)
        static let TIMEOUT_ERROR_MESSAGE = NSLocalizedString("timeout_error", comment: String.empty)
        static let CANNOT_FIND_HOST_ERROR_MESSAGE = NSLocalizedString("cannot_find_host_error", comment: String.empty)
        static let CANNOT_CONNECT_HOST_ERROR_MESSAGE = NSLocalizedString("cannot_connect_to_host_error", comment: String.empty)
        static let UNSUPPORTED_URL_ERROR_MESSAGE = NSLocalizedString("unsupported_url_error", comment: String.empty)
        static let NETWORK_CONNECTION_LOST_ERROR_MESSAGE = NSLocalizedString("network_connection_lost_error", comment: String.empty)
        static let UNEXPECTED_ERROR_MESSAGE = NSLocalizedString("unexpected_error", comment: String.empty)
    }
    
    // URL無効
    case badUrlError
    // レスポンス無し
    case noResponse
    // レスポンスエラー
    case httpResponseError(statusCode: Int?)
    // URL読み込みエラー
    case urlError(URLError.Code)
    // デコードエラー
    case decodingError
    
    internal var errorDescription: String {
        switch self {
        case .badUrlError:
            return Constants.BAD_URL_ERROR_MESSAGE
        case .noResponse:
            return Constants.NO_RESPONSE_ERROR_MESSAGE
        case .httpResponseError(statusCode: let statusCode):
            guard let statusCode = statusCode else {
                return Constants.UNEXPECTED_ERROR_MESSAGE
            }
            return NSLocalizedString(Constants.HTTP_RESPONSE_ERROR_KEY + "\(statusCode)", comment: String.empty)
        case .urlError(let urlErrorCode):
            if urlErrorCode == .notConnectedToInternet {
                // インターネットに接続できない
                return Constants.NO_CONNECTED_TO_INTERNET_ERROR_MESSAGE
            } else if urlErrorCode == .timedOut {
                // タイムアウトエラー
                return Constants.TIMEOUT_ERROR_MESSAGE
            } else if urlErrorCode == .cannotFindHost {
                // ホストが見つからない
                return Constants.CANNOT_FIND_HOST_ERROR_MESSAGE
            } else if urlErrorCode == .cannotConnectToHost {
                // ホストに接続できない
                return Constants.CANNOT_CONNECT_HOST_ERROR_MESSAGE
            } else if urlErrorCode == .unsupportedURL {
                // URLがサポートされていない
                return Constants.UNSUPPORTED_URL_ERROR_MESSAGE
            } else if urlErrorCode == .networkConnectionLost {
                // 通信中にネットワーク接続が切れる
                return Constants.NETWORK_CONNECTION_LOST_ERROR_MESSAGE
            } else {
                // その他
                return Constants.UNEXPECTED_ERROR_MESSAGE
            }
        case .decodingError:
            return Constants.UNEXPECTED_ERROR_MESSAGE
        }
    }
}

// MARK: - カレンダーイベントのエラー
enum EventError: LocalizedError {
    
    private struct Constants {
        static let EVENT_ACCESS_DENIED_ERROR_MESSAGE = NSLocalizedString("event_access_denied_error", comment: String.empty)
        static let EVENT_SAVE_FAILED_ERROR_MESSAGE = NSLocalizedString("event_save_failed_error", comment: String.empty)
    }
    
    // カレンダーへのフルアクセス権限がない
    case notAccess
    // イベントの保存失敗
    case saveFailed
    
    var errorDescription: String {
        switch self {
        case .notAccess:
            return Constants.EVENT_ACCESS_DENIED_ERROR_MESSAGE
        case .saveFailed:
            return Constants.EVENT_SAVE_FAILED_ERROR_MESSAGE
        }
    }
}
