//
//  EventAddView.swift
//  PrivateTalkApp
//
//  Created by 都甲裕希 on 2024/09/22.
//

import SwiftUI

// MARK: - Constants
private struct Constants {
    static let EVENT_SHEET_TITLE_KEY = LocalizedStringKey("event_sheet_title")
    static let EVENT_SHEET_ADD_BUTTON_TEXT_KEY = LocalizedStringKey("event_sheet_add_button_text")
    static let EVENT_SHEET_CANCEL_BUTTON_TEXT_KEY = LocalizedStringKey("event_sheet_cancel_button_text")
    static let PLACEHOLDER_TEXT_KEY = LocalizedStringKey("placeholder_title")
    static let PLACEHOLDER_PLACE_KEY = LocalizedStringKey("placeholder_place")
    static let PLACEHOLDER_URL = LocalizedStringKey("placeholder_url")
    static let PLACEHOLDER_MEMO = LocalizedStringKey("placeholder_memo")
    static let ALL_DAY_LABEL_TEXT_KEY = LocalizedStringKey("all_day_label_text")
    static let START_LABEL_TEXT_KEY = LocalizedStringKey("date_setting_view_start_label_text")
    static let END_LABEL_TEXT_KEY = LocalizedStringKey("date_setting_view_end_label_text")
    static let CANCEL_DIALOG_TITLE_KEY = LocalizedStringKey("cancel_dialog_title")
    static let CANCEL_DIALOG_DESTRUCTION_KEY = LocalizedStringKey("cancel_dialog_destruction")
    static let CANCEL_DIALOG_CONTINUE_KEY = LocalizedStringKey("cancel_dialog_continue")
    static let DATE_PICKER_HEIGHT = 22.0
    static let MEMO_TEXT_FIELD_HEIGHT = 200.0
}

// MARK: - 予定追加 View
struct EventAddView: View {
    
    // dismissハンドラー
    @Environment(\.dismiss) var dismiss
    // キーボードがアクティブかどうか
    @State var isKeyboardActive = false
    // 予定追加のViewModel
    @StateObject var eventAddViewModel: EventAddViewModel
    
    var body: some View {
        NavigationStack {
            List {
                // タイトル記入、場所またはビデオ通話欄
                Section {
                    TextFieldView(isKeyboardActive: $isKeyboardActive,
                                  text: $eventAddViewModel.titleText,
                                  placeholder: Constants.PLACEHOLDER_TEXT_KEY)
                    // TODO: 未完成
                    TextFieldView(isKeyboardActive: $isKeyboardActive,
                                  text: $eventAddViewModel.placeText,
                                  placeholder: Constants.PLACEHOLDER_PLACE_KEY)
                }
                // 日付設定欄
                Section {
                    Toggle(Constants.ALL_DAY_LABEL_TEXT_KEY, isOn: $eventAddViewModel.isAllDay)
                    DateSettingView(date: $eventAddViewModel.startDate,
                                    isAllDay: $eventAddViewModel.isAllDay,
                                    label: Constants.START_LABEL_TEXT_KEY)
                    DateSettingView(date: $eventAddViewModel.endDate,
                                    isAllDay: $eventAddViewModel.isAllDay,
                                    label: Constants.END_LABEL_TEXT_KEY)
                }
                // 繰り返し設定欄
                Section {
                    // TODO: 未完成
                    Text("繰り返し")
                }
                // 通知設定欄
                Section {
                    // TODO: 未完成
                    Text("通知")
                }
                // URL、メモ欄
                Section {
                    TextFieldView(isKeyboardActive: $isKeyboardActive,
                                  text: $eventAddViewModel.urlText,
                                  placeholder: Constants.PLACEHOLDER_URL,
                                  autocapitalization: .never)
                    TextFieldView(isKeyboardActive: $isKeyboardActive,
                                  text: $eventAddViewModel.memoText,
                                  placeholder: Constants.PLACEHOLDER_MEMO,
                                  isExpandedTextField: true)
                }
            }
            .navigationBarTitle(Constants.EVENT_SHEET_TITLE_KEY, displayMode: .inline)
            .navigationBarItems(
                leading: NavigationBarCancelButton(isEditedEvent: eventAddViewModel.isEditedEvent,
                                                   onCanceled: {
                                                       dismiss()
                                                   }),
                trailing: NavigationBarSaveButton(isEditedEvent: eventAddViewModel.isEditedEvent,
                                                  onTapped: {
                                                      dismiss()
                                                  })
            )
            .simultaneousGesture(DragGesture().onChanged({ _ in // Listのスクロールを検知
                if isKeyboardActive {
                    // キーボードを閉じる
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                                    to: nil,
                                                    from: nil,
                                                    for: nil)
                    isKeyboardActive = false
                }
            }))
            .interactiveDismissDisabled(eventAddViewModel.isEditedEvent)
        }
    }
}

// MARK: - ナビゲーションバーアイテム（キャンセルボタン）
private struct NavigationBarCancelButton: View {
    // シート内の予定の編集が行われたかどうか
    let isEditedEvent: Bool
    // ダイアログを表示するかどうか
    @State var isShowDialog = false
    // キャンセル実行時のクロージャ
    let onCanceled: () -> Void
    
    var body: some View {
        Button {
            if isEditedEvent {
                // 予定の編集がされているならダイアログを表示
                isShowDialog = true
            } else {
                // 予定の編集がされていないならモーダルを閉じる
                onCanceled()
            }
        } label: {
            Text(Constants.EVENT_SHEET_CANCEL_BUTTON_TEXT_KEY)
                .foregroundStyle(.symbol)
        }
        .confirmationDialog(Constants.CANCEL_DIALOG_TITLE_KEY,
                            isPresented: $isShowDialog,
                            titleVisibility: .visible) {
            Button(role: .destructive) {
                onCanceled()
            } label: {
                Text(Constants.CANCEL_DIALOG_DESTRUCTION_KEY)
                    .foregroundStyle(.symbol)
            }
            Button(role: .cancel) {
                
            } label: {
                Text(Constants.CANCEL_DIALOG_CONTINUE_KEY)
                    .foregroundStyle(.symbol)
            }
        }
    }
}

// MARK: - ナビゲーションバーアイテム（保存ボタン）
private struct NavigationBarSaveButton: View {
    // シート内の予定の編集が行われたかどうか（保存ボタンが有効かどうか）
    let isEditedEvent: Bool
    // 保存ボタン押下時のクロージャ
    let onTapped: () -> Void
    
    var body: some View {
        Button {
            onTapped()
        } label: {
            Text(Constants.EVENT_SHEET_ADD_BUTTON_TEXT_KEY)
                .foregroundStyle(isEditedEvent ? .symbol : .gray)
        }
        .disabled(!isEditedEvent)
    }
}

// MARK: - TextField
private struct TextFieldView: View {
    // 幅の広いTextFieldがフォーカスされているかどうか
    @FocusState private var isWideTextFieldFocused: Bool
    // キーボードがアクティブかどうか
    @Binding var isKeyboardActive: Bool
    // メッセージ
    @Binding var text: String
    // プレースホルダー
    let placeholder: LocalizedStringKey
    // TextFieldの高さを広げるかどうか
    var isExpandedTextField: Bool = false
    // テキスト入力の自動大文字化
    var autocapitalization: TextInputAutocapitalization = .sentences
    
    var body: some View {
        if isExpandedTextField {
            ZStack(alignment: .topLeading) {
                // TextFieldの高さを広げる、かつ領域全体をタップ可能にするため透明なViewを配置
                Color.clear
                    .frame(height: Constants.MEMO_TEXT_FIELD_HEIGHT)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        isKeyboardActive = true
                        isWideTextFieldFocused = true
                    }
                TextField(placeholder, text: $text, axis: .vertical) // axisで自動改行を可能に設定
                    .textInputAutocapitalization(autocapitalization)
                    .focused($isWideTextFieldFocused) // trueならキーボード表示
            }
        } else {
            TextField(placeholder, text: $text, onEditingChanged: { editing in
                if editing {
                    isKeyboardActive = true
                }
            })
                .textInputAutocapitalization(autocapitalization)
        }
    }
}

// MARK: - 日付設定 View
private struct DateSettingView: View {
    // 日付
    @Binding var date: Date
    // 終日設定かどうか
    @Binding var isAllDay: Bool
    // Listの項目名
    let label: LocalizedStringKey
    
    var body: some View {
        DatePicker(label,
                   selection: $date,
                   displayedComponents: isAllDay ? .date : [.date, .hourAndMinute])
        .frame(height: Constants.DATE_PICKER_HEIGHT)
    }
}

#Preview {
    EventAddView(eventAddViewModel: EventAddViewModel(startDate: Date(), endDate: Date()))
}
