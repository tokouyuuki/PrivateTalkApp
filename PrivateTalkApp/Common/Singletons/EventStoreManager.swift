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
    /// - parameter urlString: URL文字列
    /// - parameter notes: メモ
    /// - returns: 新規イベント
    func createNewEvent(startDate: Date,
                        endDate: Date,
                        title: String,
                        isAllDay: Bool,
                        eKRecurrenceRules: [EKRecurrenceRule]?,
                        urlString: String,
                        notes: String) -> EKEvent {
        let newEvent = EKEvent(eventStore: self.eventStore)
        newEvent.title = title.isEmpty ? Constants.INITIAL_VALUE_OF_EVENT_TITLE : title
        newEvent.startDate = startDate
        newEvent.endDate = endDate
        newEvent.isAllDay = isAllDay
        newEvent.recurrenceRules = eKRecurrenceRules
        newEvent.url = URL(string: urlString)
        newEvent.notes = notes
        newEvent.calendar = self.eventStore.defaultCalendarForNewEvents
        
        return newEvent
    }
}
