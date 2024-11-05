//
//  CustomAlertDialog.swift
//  PrivateTalkApp
//
//  Created by 都甲裕希 on 2024/10/15.
//

import Foundation
import SwiftUI

private struct Constants {
    static let EVENT_ACCESS_DENIED_ALERT_MESSAGE = NSLocalizedString("event_access_denied_alert_message", comment: String.empty)
    static let EVENT_ACCESS_DENIED_ALERT_BUTTON_TEXT_KEY = NSLocalizedString("event_access_denied_alert_button_text", comment: String.empty)
    static let DEFAULT_ALERT_TITLE_KEY = NSLocalizedString("default_alert_title", comment: String.empty)
    static let DEFAULT_ALERT_BUTTON_TEXT_KEY = NSLocalizedString("default_alert_button_text", comment: String.empty)
}

// MARK: - アラートのタイプ
enum CustomAlertType {
    case networkError(NetworkError)
    case eventError(EventError)
    case otherError
    case none
    
    init(error: PrivateTalkAppError) {
        switch error {
        case .networkError(let networkError):
            self = .networkError(networkError)
        case .eventError(let eventError):
            self = .eventError(eventError)
        case .unexpected:
            self = .otherError
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
        case .eventError(let eventError):
            if eventError.isNotAccess {
                return eventError.errorDescription ?? String.empty
            } else {
                return Constants.DEFAULT_ALERT_TITLE_KEY
            }
        default:
            return Constants.DEFAULT_ALERT_TITLE_KEY
        }
    }
    
    // アラートメッセージ
    var message: String {
        switch self {
        case .none:
            return String.empty
        case .eventError(let eventError):
            if eventError.isNotAccess {
                return Constants.EVENT_ACCESS_DENIED_ALERT_MESSAGE
            } else {
                return eventError.errorDescription ?? String.empty
            }
        case .networkError(let networkError):
            return networkError.errorDescription ?? String.empty
        case .otherError:
            return PrivateTalkAppError.unexpected.errorDescription ?? String.empty
        }
    }
}

// MARK: - カスタムアラート
struct CustomAlertDialog: ViewModifier {
    
    // アラートのタイプ
    let type: Binding<CustomAlertType>
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
                case .eventError(let eventError):
                    if eventError.isNotAccess {
                        Button(Constants.EVENT_ACCESS_DENIED_ALERT_BUTTON_TEXT_KEY) {
                            // 設定アプリのカレンダーアクセス画面を開く
                            if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(settingsUrl)
                            }
                            onDismiss()
                        }
                    } else {
                        Button(Constants.DEFAULT_ALERT_BUTTON_TEXT_KEY) {
                            onDismiss()
                        }
                    }
                default:
                    Button(Constants.DEFAULT_ALERT_BUTTON_TEXT_KEY) {
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
    
    /// エラーの内容によってカスタムアラートを生成するモディファイア
    /// - parameter type: アラートのタイプ
    /// - parameter onDismiss: アラートを閉じた時に呼ばれるクロージャ
    func customAlertDialog(type: Binding<CustomAlertType>,
                           onDismiss: @escaping () -> Void) -> some View {
        self.modifier(CustomAlertDialog(type: type, onDismiss: onDismiss))
    }
}
