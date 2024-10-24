//
//  CustomAlertDialog.swift
//  PrivateTalkApp
//
//  Created by 都甲裕希 on 2024/10/15.
//

import Foundation
import SwiftUI

// MARK: - カスタムアラート
struct CustomAlertDialog: ViewModifier {
    
    private struct Constants {
        static let EVENT_ACCESS_DENIED_ALERT_MESSAGE = NSLocalizedString("event_access_denied_alert_message", comment: String.empty)
        static let EVENT_ACCESS_DENIED_ALERT_BUTTON_TEXT_KEY = NSLocalizedString("event_access_denied_alert_button_text", comment: String.empty)
        static let DEFAULT_ALERT_TITLE_KEY = NSLocalizedString("default_alert_title", comment: String.empty)
        static let DEFAULT_ALERT_BUTTON_TEXT_KEY = NSLocalizedString("default_alert_button_text", comment: String.empty)
    }
    
    // アラートを管理する状態変数（同期用）
    @State var isShowSelfAlert: Bool = false
    // アラートを管理する状態変数（表示元からのバインド）
    @Binding var isShowAlert: Bool
    // PrivateTalkAppError
    let privateTalkAppError: PrivateTalkAppError?
    // アラートを閉じた時に呼ばれるクロージャ
    let onDismiss: () -> Void
    
    func body(content: Content) -> some View {
        switch privateTalkAppError {
            // カレンダーイベントエラーダイアログ
        case .eventError(let eventError):
            if eventError.isNotAccess {
                // カレンダーへのフルアクセスを訴求するアラート
                alert(title: eventError.errorDescription,
                      buttonText: Constants.EVENT_ACCESS_DENIED_ALERT_BUTTON_TEXT_KEY,
                      message: Constants.EVENT_ACCESS_DENIED_ALERT_MESSAGE,
                      content: content) {
                    // 設定アプリのカレンダーアクセス画面を開く
                    if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(settingsUrl)
                    }
                    onDismiss()
                }
            } else {
                alert(message: eventError.errorDescription,
                      content: content) {
                    onDismiss()
                }
            }
            // その他エラーダイアログ
        default:
            alert(message: privateTalkAppError?.errorDescription,
                  content: content) {
                onDismiss()
            }
        }
    }
    
    /// アラート
    /// - parameter title: アラートタイトル
    /// - parameter buttonText: アラートボタンテキスト
    /// - parameter message: アラートメッセージ
    /// - parameter content: content
    /// - parameter onTapped: アラートのボタンを押下した時に呼ばれるクロージャ
    func alert(title: String? = Constants.DEFAULT_ALERT_TITLE_KEY,
               buttonText: String = Constants.DEFAULT_ALERT_BUTTON_TEXT_KEY,
               message: String?,
               content: Content,
               onTapped: @escaping () -> Void) -> some View {
        content
            .onChange(of: isShowAlert, initial: true, { oldValue, newValue in
                if newValue {
                    isShowSelfAlert = true
                }
            })
            .alert(title ?? String.empty, isPresented: $isShowSelfAlert) {
                Button(buttonText) {
                    isShowSelfAlert = false
                    onTapped()
                }
            } message: {
                Text(message ?? String.empty)
            }
    }
}

// MARK: - extension
extension View {
    
    /// エラーの内容によってカスタムアラートを生成するモディファイア
    /// - parameter isShowAlert: アラートを管理する状態変数
    /// - parameter privateTalkAppError: PrivateTalkAppError
    /// - parameter onDismiss: アラートを閉じた時に呼ばれるクロージャ
    func customAlertDialog(isShowAlert: Binding<Bool>,
                           privateTalkAppError: PrivateTalkAppError?,
                           onDismiss: @escaping () -> Void) -> some View {
        self.modifier(CustomAlertDialog(isShowAlert: isShowAlert,
                                        privateTalkAppError: privateTalkAppError,
                                        onDismiss: onDismiss))
    }
}
