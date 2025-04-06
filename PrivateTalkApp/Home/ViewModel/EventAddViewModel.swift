//
//  EventAddViewModel.swift
//  PrivateTalkApp
//
//  Created by 都甲裕希 on 2024/10/11.
//

import Foundation
import EventKit

// MARK: - 予定追加 ViewModel
@MainActor
final class EventAddViewModel: ObservableObject {
    
    // 開始日の初期値
    private let initialStartDate: Date
    // 終了日の初期値
    private let initialEndDate: Date
    // カレンダーイベントRepository
    private let eventRepository = EventRepository()
    // 終日設定かどうか
    @Published var isAllDay = false
    // タイトル
    @Published var titleText = String.empty
    // 場所
    @Published var placeText = String.empty
    // URL
    @Published var urlText = String.empty
    // メモ
    @Published var memoText = String.empty
    // 開始日
    @Published var startDate: Date
    // 終了日
    @Published var endDate: Date
    // 取り消し線を終了日に表示するかどうか
    @Published var isStrikethrough: Bool = false
    // イベントエラーが発生した際に表示するアラートのタイプ
    @Published var eventErrorAlertType: EventErrorAlertType = .none
    // モーダルを閉じるかどうか
    @Published var shouldDismiss = false
    // キャンセルボタン押下時の確認アラートを表示するかどうか
    @Published var showCancelConfirmationAlert = false
    
    /// - parameter selectedDate: カレンダーで選択している日付
    init(selectedDate: Date) {
        self.initialStartDate = selectedDate
        self.initialEndDate = selectedDate.addHours(1) ?? selectedDate
        self.startDate = selectedDate
        self.endDate = selectedDate.addHours(1) ?? selectedDate
    }
    
    // 予定の編集が行われたかどうか
    var isEditedEvent: Bool {
        return self.isAllDay
        || self.startDate != self.initialStartDate
        || self.endDate != self.initialEndDate
        || !self.titleText.isEmpty
        || !self.placeText.isEmpty
        || !self.urlText.isEmpty
        || !self.memoText.isEmpty
    }
    
    /// 予定を追加する
    func addEvent() {
        Task {
            do {
                // 入力値を元に、新規予定を作成
                let event = EventStoreManager.shared.createNewEvent(startDate: self.startDate,
                                                                    endDate: self.endDate,
                                                                    title: self.titleText,
                                                                    isAllDay: self.isAllDay,
                                                                    notes: self.memoText)
                // 予定を追加
                try eventRepository.addEvent(event: event)
                self.shouldDismiss = true
            } catch let eventError as EventError {
                self.eventErrorAlertType = .init(error: eventError)
            } catch {
                Logger().log(error.localizedDescription, level: .error)
                self.eventErrorAlertType = .init(error: .unexpected)
            }
        }
    }
    
    /// キャンセルボタン押下時の処理
    func onTapCancelButton() {
        // 編集中の予定がある場合、キャンセル確認アラートを表示
        if isEditedEvent {
            self.showCancelConfirmationAlert = true
        } else {
            self.shouldDismiss = true
        }
    }
    
    /// Datepickerで開始日が変更された時に行う処理
    /// - parameter newStartDate: 新しい開始日
    func handleStartDateChange(_ newStartDate: Date) {
        self.startDate = newStartDate
        self.endDate = newStartDate.addHours(1) ?? newStartDate
    }
    
    /// Datepickerで開始日が変更された時に行う処理
    /// - parameter newEndDate: 新しい開始日
    func handleEndDateChange(_ newEndDate: Date) {
        self.endDate = newEndDate
        self.isStrikethrough = self.startDate > newEndDate
    }
    
    /// 終日トグルが変更された時に行う処理
    /// - parameter newValue: 終日かどうかの新しい判定
    func handleIsAllDayChange(_ newValue: Bool) {
        self.isAllDay = newValue
        if newValue {
            self.isStrikethrough = !Calendar.current.isDate(self.startDate,
                                                            inSameDayAs: self.endDate)
        } else {
            self.isStrikethrough = self.startDate > self.endDate
        }
    }
}
