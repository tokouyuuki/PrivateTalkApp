//
//  EventStoreManager.swift
//  PrivateTalkApp
//
//  Created by 都甲裕希 on 2024/10/11.
//

import Foundation
import EventKit

// MARK: - EKEventStoreを管理するクラス
final class EventStoreManager {
    
    private struct Constants {
        static let INITIAL_VALUE_OF_EVENT_TITLE = NSLocalizedString("event_sheet_title", comment: String.empty)
    }
    
    static let shared = EventStoreManager()
    
    // イベント（カレンダーイベントやリマインダー）を管理するためのインスタンス
    // このインスタンスで、iOSのカレンダーと連携を行う
    let eventStore = EKEventStore()
    
    private init() {}
    
    /// カレンダーイベントへのアクセス権限があるかどうか
    /// - returns: 権限があればtrue / 権限がなければfalse
    func isFullAccessToEvents() -> Bool {
        // カレンダーイベントへのアクセスステータスを取得
        let status = EKEventStore.authorizationStatus(for: .event)
        
        return status == .fullAccess
    }
    
    /// 新規イベントを作成
    /// - parameter startDate: 開始日
    /// - parameter endDate: 終了日
    /// - parameter title: タイトル
    /// - parameter isAllDay: 終日かどうか
    /// - parameter eKRecurrenceRules: 繰り返しルール
    /// - parameter ekCalendar: カレンダー
    /// - parameter urlString: URL文字列
    /// - parameter notes: メモ
    /// - returns: 新規イベント
    func createNewEvent(startDate: Date,
                        endDate: Date,
                        title: String,
                        isAllDay: Bool,
                        eKRecurrenceRules: [EKRecurrenceRule]?,
                        ekCalendar: EKCalendar?,
                        urlString: String,
                        notes: String) -> EKEvent {
        let newEvent = EKEvent(eventStore: self.eventStore)
        newEvent.title = title.isEmpty ? Constants.INITIAL_VALUE_OF_EVENT_TITLE : title
        newEvent.startDate = startDate
        newEvent.endDate = endDate
        newEvent.isAllDay = isAllDay
        newEvent.recurrenceRules = eKRecurrenceRules
        newEvent.calendar = ekCalendar ?? self.eventStore.defaultCalendarForNewEvents
        newEvent.url = URL(string: urlString)
        newEvent.notes = notes
        
        return newEvent
    }
    
    /// カレンダーの種類タイトルを取得
    /// - returns: カレンダーの種類タイトル
    func getDefaultEKCalendarTitle() -> String {
        return self.eventStore.defaultCalendarForNewEvents?.title
        ?? self.eventStore.calendars(for: .event).first!.title
    }
    
    /// カレンダーを取得
    /// - returns: カレンダー（EKCalendar）
    func getEKCalendars() -> [EKCalendar] {
        return self.eventStore.calendars(for: .event).filter {
            // 誕生日と日本の祝日は取り除く
            $0.calendarIdentifier != "D0C0429F-B992-410F-A92C-BFE8FFD5D974"
            && $0.calendarIdentifier != "B753962B-BF0E-4943-A6DC-89946DC032CD"
        }
    }
}
