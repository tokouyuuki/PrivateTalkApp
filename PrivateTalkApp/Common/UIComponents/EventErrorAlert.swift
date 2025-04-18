//
//  EventErrorAlert.swift
//  PrivateTalkApp
//
//  Created by 都甲裕希 on 2024/10/15.
//

import Foundation
import SwiftUI

private struct Constants {
    static let EVENT_ACCESS_DENIED_ALERT_MESSAGE = NSLocalizedString("event_access_denied_alert_message", comment: String.empty)
    static let EVENT_ACCESS_DENIED_ALERT_BUTTON_TEXT = NSLocalizedString("event_access_denied_alert_button_text", comment: String.empty)
    static let DEFAULT_ALERT_TITLE = NSLocalizedString("default_alert_title", comment: String.empty)
    static let DEFAULT_ALERT_BUTTON_TEXT = NSLocalizedString("default_alert_button_text", comment: String.empty)
}

// MARK: - EventErrorアラートのタイプ
enum EventErrorAlertType {
    case noCalendarPermission(EventError)
    case otherEventError(EventError)
    case none
    
    init(error: EventError) {
        switch error {
        case .notAccess:
            self = .noCalendarPermission(error)
        case .saveFailed:
            self = .otherEventError(error)
        case .unexpected:
            self = .otherEventError(error)
        }
    }
    
    // アラートを表示するかどうか
    var isPresented: Bool {
        switch self {
        case .none:
            return false
        default:
            return true
        }
    }
    
    // アラートタイトル
    var title: String {
        switch self {
        case .none:
            return String.empty
        case .noCalendarPermission(let eventError):
            return eventError.errorDescription ?? String.empty
        case .otherEventError(_):
            return Constants.DEFAULT_ALERT_TITLE
        }
    }
    
    // アラートメッセージ
    var message: String {
        switch self {
        case .none:
            return String.empty
        case .noCalendarPermission(_):
            return Constants.EVENT_ACCESS_DENIED_ALERT_MESSAGE
        case .otherEventError(let eventError):
            return eventError.errorDescription ?? String.empty
        }
    }
}

// MARK: - EventErrorアラート
struct EventErrorAlert: ViewModifier {
    
    // アラートのタイプ
    let type: Binding<EventErrorAlertType>
    // アラートを閉じた時に呼ばれるクロージャ
    let onDismiss: () -> Void
    
    func body(content: Content) -> some View {
        content
            .alert(type.wrappedValue.title,
                   isPresented: .init(get: { type.wrappedValue.isPresented },
                                      set: { _ in type.wrappedValue = .none })) {
                switch type.wrappedValue {
                case .none:
                    EmptyView()
                case .noCalendarPermission(_):
                        Button(Constants.EVENT_ACCESS_DENIED_ALERT_BUTTON_TEXT) {
                            // 設定アプリのカレンダーアクセス画面を開く
                            if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(settingsUrl)
                            }
                            onDismiss()
                        }
                case .otherEventError(_):
                        Button(Constants.DEFAULT_ALERT_BUTTON_TEXT) {
                            onDismiss()
                        }
                }
            } message: {
                Text(type.wrappedValue.message)
            }
    }
}

// MARK: - extension
extension View {
    
    /// イベントエラーの内容によってアラートを生成するモディファイア
    /// - parameter type: アラートのタイプ
    /// - parameter onDismiss: アラートを閉じた時に呼ばれるクロージャ
    func eventErrorAlert(type: Binding<EventErrorAlertType>,
                           onDismiss: @escaping () -> Void) -> some View {
        self.modifier(EventErrorAlert(type: type, onDismiss: onDismiss))
    }
}
