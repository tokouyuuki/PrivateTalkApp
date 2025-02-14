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
        static let INITIAL_VALUE_OF_EVENT_TITLE_KEY = "event_sheet_title"
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
    /// - parameter notes: メモ
    /// - returns: 新規イベント
    func createNewEvent(startDate: Date,
                        endDate: Date,
                        title: String,
                        isAllDay: Bool,
                        notes: String) -> EKEvent {
        let newEvent = EKEvent(eventStore: self.eventStore)
        if title.isEmpty {
            newEvent.title = NSLocalizedString(Constants.INITIAL_VALUE_OF_EVENT_TITLE_KEY, comment: String.empty)
        } else {
            newEvent.title = title
        }
        newEvent.startDate = startDate
        newEvent.endDate = endDate
        newEvent.isAllDay = isAllDay
        newEvent.notes = notes
        newEvent.calendar = self.eventStore.defaultCalendarForNewEvents
        
        return newEvent
    }
}
