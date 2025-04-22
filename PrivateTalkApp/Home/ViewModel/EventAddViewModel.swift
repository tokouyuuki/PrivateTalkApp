//
//  EventAddViewModel.swift
//  PrivateTalkApp
//
//  Created by 都甲裕希 on 2024/10/11.
//

import Foundation
import EventKit

// MARK: - イベントの繰り返し設定のタイプ
enum RecurrenceRuleType: CaseIterable, CustomStringConvertible {
    // 繰り返しなし
    case none
    // 毎日
    case daily
    // 毎週
    case weekly
    // 隔週
    case biweekly
    // 毎月
    case monthly
    // 毎年
    case yearly
    
    var description: String {
        switch self {
        case .none:
            NSLocalizedString("recurrence_rule_never", comment: String.empty)
        case .daily:
            NSLocalizedString("recurrence_rule_daily", comment: String.empty)
        case .weekly:
            NSLocalizedString("recurrence_rule_weekly", comment: String.empty)
        case .biweekly:
            NSLocalizedString("recurrence_rule_biweekly", comment: String.empty)
        case .monthly:
            NSLocalizedString("recurrence_rule_monthly", comment: String.empty)
        case .yearly:
            NSLocalizedString("recurrence_rule_yearly", comment: String.empty)
        }
    }
}

// MARK: - イベントの繰り返し終了のタイプ
enum RecurrenceEndType: CaseIterable, CustomStringConvertible {
    // 繰り返し終了日なし
    case none
    // 指定終了日あり
    case specifiedDate
    
    var description: String {
        switch self {
        case .none:
            NSLocalizedString("recurrence_rule_never", comment: String.empty)
        case .specifiedDate:
            NSLocalizedString("recurrence_specified_date", comment: String.empty)
        }
    }
}

// MARK: - イベントの事前アラームのタイプ
enum AlarmType: CaseIterable, CustomStringConvertible {
    case none
    case onTime
    case fiveMinutesBefore
    case tenMinutesBefore
    case fifteenMinutesBefore
    case thirtyMinutesBefore
    case oneHourBefore
    case twoHoursBefore
    case oneDayBefore
    case twoDaysBefore
    case oneWeekBefore
    
    var description: String {
        switch self {
        case .none:
            NSLocalizedString("no_alarm", comment: String.empty)
        case .onTime:
            NSLocalizedString("alarm_scheduled_time", comment: String.empty)
        case .fiveMinutesBefore:
            NSLocalizedString("alarm_5_minutes_before", comment: String.empty)
        case .tenMinutesBefore:
            NSLocalizedString("alarm_10_minutes_before", comment: String.empty)
        case .fifteenMinutesBefore:
            NSLocalizedString("alarm_15_minutes_before", comment: String.empty)
        case .thirtyMinutesBefore:
            NSLocalizedString("alarm_30_minutes_before", comment: String.empty)
        case .oneHourBefore:
            NSLocalizedString("alarm_1_hour_before", comment: String.empty)
        case .twoHoursBefore:
            NSLocalizedString("alarm_2_hours_before", comment: String.empty)
        case .oneDayBefore:
            NSLocalizedString("alarm_1_day_before", comment: String.empty)
        case .twoDaysBefore:
            NSLocalizedString("alarm_2_days_before", comment: String.empty)
        case .oneWeekBefore:
            NSLocalizedString("alarm_1_week_before", comment: String.empty)
        }
    }
    
    var alarm: EKAlarm? {
        switch self {
        case .none:
            return nil
        case .onTime:
            return EKAlarm(relativeOffset: 0)
        case .fiveMinutesBefore:
            return EKAlarm(relativeOffset: 60 * -5)
        case .tenMinutesBefore:
            return EKAlarm(relativeOffset: 60 * -10)
        case .fifteenMinutesBefore:
            return EKAlarm(relativeOffset: 60 * -15)
        case .thirtyMinutesBefore:
            return EKAlarm(relativeOffset: 60 * -30)
        case .oneHourBefore:
            return EKAlarm(relativeOffset: 60 * -60)
        case .twoHoursBefore:
            return EKAlarm(relativeOffset: 60 * 60 * -2)
        case .oneDayBefore:
            return EKAlarm(relativeOffset: 60 * 60 * -24)
        case .twoDaysBefore:
            return EKAlarm(relativeOffset: 60 * 60 * 24 * -2)
        case .oneWeekBefore:
            return EKAlarm(relativeOffset: 60 * 60 * 24 * -7)
        }
    }
}

// MARK: - 予定追加 ViewModel
@MainActor
final class EventAddViewModel: ObservableObject {
    
    // 開始日の初期値
    private let initialStartDate: Date
    // 終了日の初期値
    private let initialEndDate: Date
    // 終了日が編集されたかどうか
    private var isEditedEndDate = false
    // カレンダーイベントRepository
    private let eventRepository = EventRepository()
    // カレンダーリスト
    private let calendars: [EKCalendar]
    // 終日設定かどうか
    @Published var isAllDay = false
    // タイトル
    @Published var titleText = String.empty
    // 場所
    @Published var placeText = String.empty
    // 繰り返しルールタイプ
    @Published var recurrenceRuleType = RecurrenceRuleType.none
    // 繰り返しルールの終了タイプ
    @Published var recurrenceEndType = RecurrenceEndType.none
    // 繰り返しルールの終了日
    @Published var recurrenceEndDate: Date
    // 選択中のカレンダー
    @Published var calendarTitle: String
    // アラームタイプ
    @Published var alarmType = AlarmType.none
    // 予備のアラームタイプ
    @Published var secondAlarmType = AlarmType.none
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
        self.recurrenceEndDate = selectedDate
        self.calendarTitle = EventStoreManager.shared.getDefaultEKCalendarTitle()
        self.calendars = EventStoreManager.shared.getEKCalendars()
    }
    
    // 予定の編集が行われたかどうか
    var isEditedEvent: Bool {
        return self.isAllDay
        || self.startDate != self.initialStartDate
        || self.endDate != self.initialEndDate
        || !self.titleText.isEmpty
        || !self.placeText.isEmpty
        || self.recurrenceRuleType != .none
        || self.alarmType != .none
        || !self.urlText.isEmpty
        || !self.memoText.isEmpty
    }
    
    // MARK: - Privateメソッド
    /// 繰り返しルールを生成
    /// - returns: 繰り返しルール（EKRecurrenceRule）
    private func createEKRecurrenceRules() -> [EKRecurrenceRule]? {
        let recurrenceEnd = self.recurrenceEndType == .none ? nil : EKRecurrenceEnd(end: self.recurrenceEndDate)
        switch self.recurrenceRuleType {
        case .none:
            return nil
        case .daily:
            return [EKRecurrenceRule(recurrenceWith: .daily, interval: 1, end: recurrenceEnd)]
        case .weekly:
            return [EKRecurrenceRule(recurrenceWith: .weekly, interval: 1, end: recurrenceEnd)]
        case .biweekly:
            return [EKRecurrenceRule(recurrenceWith: .weekly, interval: 2, end: recurrenceEnd)]
        case .monthly:
            return [EKRecurrenceRule(recurrenceWith: .monthly, interval: 1, end: recurrenceEnd)]
        case .yearly:
            return [EKRecurrenceRule(recurrenceWith: .yearly, interval: 1, end: recurrenceEnd)]
        }
    }
    
    /// アラームを生成
    /// - returns: アラーム（EKAlarm）
    private func createEKAlarm() -> [EKAlarm]? {
        var alarms: [EKAlarm] = []
        if let alarm = self.alarmType.alarm {
            alarms.append(alarm)
            if let secondAlarm = self.secondAlarmType.alarm {
                alarms.append(secondAlarm)
            }
            return alarms
        }
        return nil
    }
    
    // MARK: - Publicメソッド
    /// 予定を追加する
    func addEvent() {
        Task {
            do {
                let recurrenceRules = self.createEKRecurrenceRules()
                let calendar = self.calendars.first { $0.title == self.calendarTitle }
                let alarms = self.createEKAlarm()
                // 入力値を元に、新規予定を作成
                let event = EventStoreManager.shared.createNewEvent(startDate: self.startDate,
                                                                    endDate: self.endDate,
                                                                    title: self.titleText,
                                                                    isAllDay: self.isAllDay,
                                                                    eKRecurrenceRules: recurrenceRules,
                                                                    ekCalendar: calendar,
                                                                    ekAlarm: alarms,
                                                                    urlString: self.urlText,
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
        if !self.isEditedEndDate {
            // 終了日が編集されていない場合
            self.endDate = newStartDate.addHours(1) ?? newStartDate
        } else if self.isStrikethrough {
            // 取り消し線が表示されている場合
            self.isStrikethrough = newStartDate > self.endDate
        } else if self.isEditedEndDate && !self.isStrikethrough {
            // 編集がされている場合、かつ取り消し線が非表示の場合
            let addHours = (self.endDate.day - self.startDate.day) * 24 + 1
            self.endDate = newStartDate.addHours(addHours) ?? newStartDate
        }
        self.startDate = newStartDate
    }
    
    /// Datepickerで開始日が変更された時に行う処理
    /// - parameter newEndDate: 新しい開始日
    func handleEndDateChange(_ newEndDate: Date) {
        self.endDate = newEndDate
        self.isStrikethrough = self.startDate > newEndDate
        self.isEditedEndDate = true
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
    
    /// 繰り返しルールの終了を設定する項目を表示するかどうか
    /// - returns: true: 表示する / false: 表示しない
    func isShowRecurrenceEnd() -> Bool {
        return self.recurrenceRuleType != .none
    }
    
    /// 繰り返しルール終了日の項目を表示するかどうか
    /// - returns: true: 表示する / false: 表示しない
    func isShowRecurrenceEndDate() -> Bool {
        return self.recurrenceEndType == .specifiedDate && self.recurrenceRuleType != .none
    }
    
    /// カレンダーの種類タイトルのリストを取得
    /// - returns: カレンダーの種類タイトル
    func getCalendarTitles() -> [String] {
        return self.calendars.map { $0.title }
    }
    
    /// 予備の通知を表示するかどうか
    /// - returns: true: 表示する / false: 表示しない
    func isShowSecondAlarm() -> Bool {
        return self.alarmType != .none
    }
}
