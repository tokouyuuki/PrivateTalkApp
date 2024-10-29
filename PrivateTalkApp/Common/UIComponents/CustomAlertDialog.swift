//
//  CustomAlertDialog.swift
//  PrivateTalkApp
//
//  Created by 都甲裕希 on 2024/10/15.
//

import Foundation
import SwiftUI

private struct MasappErrorAlertConstants {
    static let EVENT_ACCESS_DENIED_ALERT_MESSAGE = NSLocalizedString("event_access_denied_alert_message", comment: String.empty)
    static let EVENT_ACCESS_DENIED_ALERT_BUTTON_TEXT_KEY = NSLocalizedString("event_access_denied_alert_button_text", comment: String.empty)
    static let DEFAULT_ALERT_TITLE_KEY = NSLocalizedString("default_alert_title", comment: String.empty)
    static let DEFAULT_ALERT_BUTTON_TEXT_KEY = NSLocalizedString("default_alert_button_text", comment: String.empty)
}

enum MasappAlertType {
    case none
    case noCalendarPermission(Error)
    case simpleError(Error?)

    init(error: PrivateTalkAppError) {
        switch error {
        case .networkError(let networkError):
            self = .simpleError(networkError)
        case .eventError(let eventError):
            self = .noCalendarPermission(eventError)
        case .unexpected:
            self = .simpleError(nil)
        }
    }

    var isPresented: Bool {
        switch self {
        case .none:
            return false
        default:
            return true
        }
    }

    var title: String {
        switch self {
        case .none:
            return ""
        case .noCalendarPermission(let error):
            return error.localizedDescription
        case .simpleError:
            return MasappErrorAlertConstants.DEFAULT_ALERT_TITLE_KEY
        }
    }

    var message: String {
        switch self {
        case .none:
            return ""
        case .noCalendarPermission(let error):
            return MasappErrorAlertConstants.EVENT_ACCESS_DENIED_ALERT_MESSAGE
        case .simpleError(let error):
            return error?.localizedDescription ?? ""
        }
    }
}

struct MasappAlert: ViewModifier {
    let type: Binding<MasappAlertType>
    let onDismiss: () -> Void

    @ViewBuilder
    func body(content: Content) -> some View {
        content
            .alert(
                type.wrappedValue.title,
                isPresented: .init(
                    get: { type.wrappedValue.isPresented },
                    set: { _ in type.wrappedValue = .none }),
                actions: {
                    switch type.wrappedValue {
                    case .none:
                        EmptyView()
                    case .noCalendarPermission(let error):
                        Button(MasappErrorAlertConstants.EVENT_ACCESS_DENIED_ALERT_BUTTON_TEXT_KEY) {
                            if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(settingsUrl)
                            }
                            onDismiss()
                        }
                    case .simpleError(let error):
                        Button(MasappErrorAlertConstants.DEFAULT_ALERT_BUTTON_TEXT_KEY) {
                            onDismiss()
                        }
                    }
                },
                message: {
                    Text(type.wrappedValue.message)
                }
            )
    }
}
// MARK: - extension
extension View {
    func masappAlert(type: Binding<MasappAlertType>, onDismiss: @escaping () -> Void) -> some View {
        self.modifier(MasappAlert(type: type, onDismiss: onDismiss))
    }
}
