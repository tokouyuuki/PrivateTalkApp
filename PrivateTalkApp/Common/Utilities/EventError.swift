//
//  EventError.swift
//  PrivateTalkApp
//
//  Created by 都甲裕希 on 2024/11/05.
//

import Foundation

// MARK: - カレンダーイベントのエラー
enum EventError: LocalizedError {
    
    private struct Constants {
        static let EVENT_ACCESS_DENIED_ERROR_MESSAGE = NSLocalizedString("event_access_denied_error", comment: String.empty)
        static let EVENT_SAVE_FAILED_ERROR_MESSAGE = NSLocalizedString("event_save_failed_error", comment: String.empty)
        static let UNEXPECTED_ERROR_MESSAGE = NSLocalizedString("unexpected_error", comment: String.empty)
    }
    
    // カレンダーへのフルアクセス権限がない
    case notAccess
    // イベントの保存失敗
    case saveFailed
    // 予期せぬエラー
    case unexpected
    
    var errorDescription: String? {
        switch self {
        case .notAccess:
            return Constants.EVENT_ACCESS_DENIED_ERROR_MESSAGE
        case .saveFailed:
            return Constants.EVENT_SAVE_FAILED_ERROR_MESSAGE
        case .unexpected:
            return Constants.UNEXPECTED_ERROR_MESSAGE
        }
    }
    
    // アクセス権限があるかどうか
    var isNotAccess: Bool {
        return self == .notAccess
    }
}
