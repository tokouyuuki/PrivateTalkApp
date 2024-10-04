//
//  EventSheetView.swift
//  PrivateTalkApp
//
//  Created by 都甲裕希 on 2024/09/22.
//

import SwiftUI

// MARK: - Constants
private struct Constants {
    static let EVENT_SHEET_TITLE_KEY = LocalizedStringKey("event_sheet_title")
    static let EVENT_SHEET_SAVE_BUTTON_TEXT_KEY = LocalizedStringKey("event_sheet_save_button_text")
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

// MARK: - 予定追加シート（モーダル）
struct EventSheetView: View {
    // 選択している日付（開始日）
    let selectedStartDate: Date
    // 選択している日付（終了日）
    let selectedEndDate: Date
    // 終日設定かどうか（トグルをONにすれば、true）
    @State var isAllDay = false
    // タイトル
    @State var titleText = String.empty
    // 場所
    @State var placeText = String.empty
    // URL
    @State var urlText = String.empty
    // メモ
    @State var memoText = String.empty
    // 開始日
    @State var startDate: Date?
    // 終了日
    @State var endDate: Date?
    // キーボードがアクティブかどうか
    @State var isKeyboardActive = false
    // シート内の予定の編集が行われたかどうか
    private var isEditedEvent: Bool {
        return isAllDay
        || (startDate != selectedStartDate && startDate != nil)
        || (endDate != selectedEndDate && endDate != nil)
        || !titleText.isEmpty
        || !placeText.isEmpty
        || !urlText.isEmpty
        || !memoText.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            List {
                // タイトル記入欄
                Section {
                    TextFieldView(isKeyboardActive: $isKeyboardActive,
                                  text: $titleText,
                                  placeholder: Constants.PLACEHOLDER_TEXT_KEY)
                }
                // 日付設定欄
                Section {
                    Toggle(Constants.ALL_DAY_LABEL_TEXT_KEY, isOn: $isAllDay)
                    DateSettingView(date: selectedStartDate,
                                    isAllDay: $isAllDay,
                                    label: Constants.START_LABEL_TEXT_KEY,
                                    onChanged: { newValue in
                        self.startDate = newValue
                    })
                    DateSettingView(date: selectedEndDate,
                                    isAllDay: $isAllDay,
                                    label: Constants.END_LABEL_TEXT_KEY,
                                    onChanged: { newValue in
                        self.endDate = newValue
                    })
                }
                // 場所設定欄
                Section {
                    TextFieldView(isKeyboardActive: $isKeyboardActive,
                                  text: $placeText,
                                  placeholder: Constants.PLACEHOLDER_PLACE_KEY)
                    TextFieldView(isKeyboardActive: $isKeyboardActive,
                                  text: $urlText,
                                  placeholder: Constants.PLACEHOLDER_URL,
                                  autocapitalization: .never)
                }
                // メモ欄
                Section {
                    TextFieldView(isKeyboardActive: $isKeyboardActive,
                                  text: $memoText,
                                  placeholder: Constants.PLACEHOLDER_MEMO,
                                  isExpandedTextField: true)
                }
            }
            .navigationBarTitle(Constants.EVENT_SHEET_TITLE_KEY, displayMode: .inline)
            .navigationBarItems(
                leading: NavigationBarCancelButton(isEditedEvent: isEditedEvent),
                trailing: NavigationBarSaveButton(isEditedEvent: isEditedEvent)
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
        }
    }
}

// MARK: - ナビゲーションバーアイテム（キャンセルボタン）
private struct NavigationBarCancelButton: View {
    // シート内の予定の編集が行われたかどうか
    var isEditedEvent: Bool
    // ダイアログを表示するかどうか
    @State var isShowDialog = false
    // dismissハンドラー
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        Button {
            if isEditedEvent {
                // 予定の編集がされているならダイアログを表示
                isShowDialog = true
            } else {
                // 予定の編集がされていないならモーダルを閉じる
                dismiss()
            }
        } label: {
            Text(Constants.EVENT_SHEET_CANCEL_BUTTON_TEXT_KEY)
                .foregroundStyle(.symbol)
        }
        .confirmationDialog(Constants.CANCEL_DIALOG_TITLE_KEY,
                            isPresented: $isShowDialog,
                            titleVisibility: .visible) {
            Button(role: .destructive) {
                dismiss()
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
    var isEditedEvent: Bool
    // dismissハンドラー
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        Button {
            dismiss()
        } label: {
            Text(Constants.EVENT_SHEET_SAVE_BUTTON_TEXT_KEY)
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
                // TextFieldの高さを広げる、かつ領域全体をタップ可能にするため透明なButtonを配置
                Button {
                    isKeyboardActive = true
                    isWideTextFieldFocused = true
                } label: {
                    Color.clear
                        .frame(height: Constants.MEMO_TEXT_FIELD_HEIGHT)
                }
                TextField(placeholder, text: $text, axis: .vertical)
                    .autocorrectionDisabled() // 自動改行を可能に設定
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
    @State var date: Date
    // 終日設定かどうか
    @Binding var isAllDay: Bool
    // Listの項目名
    let label: LocalizedStringKey
    // 日付変更時のクロージャ
    let onChanged: (Date) -> Void
    
    var body: some View {
        DatePicker(label,
                   selection: $date,
                   displayedComponents: isAllDay ? .date : [.date, .hourAndMinute])
        .onChange(of: date, perform: { newValue in
            // トグルOMで、newValue = trueとなる
            onChanged(newValue)
        })
        .frame(height: Constants.DATE_PICKER_HEIGHT)
    }
}

#Preview {
    EventSheetView(selectedStartDate: Date(), selectedEndDate: Date())
}
