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
    static let PLACEHOLDER_RECURRENCE_RULE_KEY = LocalizedStringKey("placeholder_recurrence_rule")
    static let PLACEHOLDER_RECURRENCE_END_KEY = LocalizedStringKey("placeholder_recurrence_end")
    static let PLACEHOLDER_RECURRENCE_END_DATE_KEY = LocalizedStringKey("placeholder_recurrence_end_date")
    static let PLACEHOLDER_URL = LocalizedStringKey("placeholder_url")
    static let PLACEHOLDER_MEMO = LocalizedStringKey("placeholder_memo")
    static let ALL_DAY_LABEL_TEXT_KEY = LocalizedStringKey("all_day_label_text")
    static let START_LABEL_TEXT_KEY = LocalizedStringKey("date_setting_view_start_label_text")
    static let END_LABEL_TEXT_KEY = LocalizedStringKey("date_setting_view_end_label_text")
    static let CANCEL_DIALOG_TITLE_KEY = LocalizedStringKey("cancel_dialog_title")
    static let CANCEL_DIALOG_DESTRUCTION_KEY = LocalizedStringKey("cancel_dialog_destruction")
    static let CANCEL_DIALOG_CONTINUE_KEY = LocalizedStringKey("cancel_dialog_continue")
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
                    Toggle(Constants.ALL_DAY_LABEL_TEXT_KEY,
                           isOn: .init(get: { eventAddViewModel.isAllDay },
                                       set: eventAddViewModel.handleIsAllDayChange))
                    DateSettingView(date: .init(get: { eventAddViewModel.startDate },
                                                set: eventAddViewModel.handleStartDateChange),
                                    isAllDay: eventAddViewModel.isAllDay,
                                    label: Constants.START_LABEL_TEXT_KEY)
                    ZStack {
                        if eventAddViewModel.isStrikethrough {
                            StrikethroughOverlay()
                        }
                        DateSettingView(date: .init(get: { eventAddViewModel.endDate },
                                                    set: eventAddViewModel.handleEndDateChange),
                                        isAllDay: eventAddViewModel.isAllDay,
                                        label: Constants.END_LABEL_TEXT_KEY)
                    }
                }
                // 繰り返し設定欄
                Section {
                    PickerView(selection: $eventAddViewModel.recurrenceRuleType,
                               title: Constants.PLACEHOLDER_RECURRENCE_RULE_KEY)
                    if eventAddViewModel.isShowRecurrenceEnd() {
                        PickerView(selection: $eventAddViewModel.recurrenceEnd,
                                   title: Constants.PLACEHOLDER_RECURRENCE_END_KEY)
                    }
                    if eventAddViewModel.isShowRecurrenceEndDate() {
                        DateSettingView(date: $eventAddViewModel.recurrenceEndDate,
                                        isAllDay: true,
                                        label: Constants.PLACEHOLDER_RECURRENCE_END_DATE_KEY)
                    }
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
            .toolbar {
                // キャンセルボタン
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        eventAddViewModel.onTapCancelButton()
                    } label: {
                        Text(Constants.EVENT_SHEET_CANCEL_BUTTON_TEXT_KEY)
                            .foregroundStyle(.symbol)
                    }
                }
                // 保存ボタン
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        eventAddViewModel.addEvent()
                    } label: {
                        Text(Constants.EVENT_SHEET_ADD_BUTTON_TEXT_KEY)
                            .foregroundStyle(eventAddViewModel.isEditedEvent ? .symbol : .gray)
                    }
                    .disabled(!eventAddViewModel.isEditedEvent)
                }
            }
            .onChange(of: eventAddViewModel.shouldDismiss, { oldValue, newValue in
                if newValue {
                    dismiss()
                }
            })
            .eventErrorAlert(type: $eventAddViewModel.eventErrorAlertType, onDismiss: {})
            .confirmationDialog(Constants.CANCEL_DIALOG_TITLE_KEY,
                                isPresented: $eventAddViewModel.showCancelConfirmationAlert,
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
                    .frame(height: 200.0)
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
    var isAllDay: Bool
    // Listの項目名
    let label: LocalizedStringKey
    
    var body: some View {
        DatePicker(label,
                   selection: $date,
                   displayedComponents: isAllDay ? .date : [.date, .hourAndMinute])
        .frame(height: 22.0)
        .onAppear {
            UIDatePicker.appearance().minuteInterval = 5
        }
    }
}

// MARK: - 取り消し戦
private struct StrikethroughOverlay: View {
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let width = geometry.size.width
                let height = geometry.size.height
                // 横線を引く（左端から右端）
                path.move(to: CGPoint(x: 0, y: height / 2))
                path.addLine(to: CGPoint(x: width, y: height / 2))
            }
            .stroke(Color.black)
        }
    }
}

// MARK: - 選択肢を表示するためのPickerView
private struct PickerView<T: PickerRepresentable>: View {
    // 現在選択されている値
    @Binding var selection: T
    // タイトル
    let title: LocalizedStringKey
    
    var body: some View {
        Picker(title, selection: $selection) {
            ForEach(T.allCases, id: \.self) {
                Text($0.description)
            }
        }
        .pickerStyle(.menu)
        .tint(.gray)
    }
}

#Preview {
    EventAddView(eventAddViewModel: EventAddViewModel(selectedDate: Date()))
}
