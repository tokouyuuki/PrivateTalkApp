//
//  EKEventStore.swift
//  PrivateTalkApp
//
//  Created by 都甲裕希 on 2024/10/11.
//

import Foundation
import EventKit

// MARK: - EKEventStoreを管理するクラス
final class EventStoreManager {
    
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
        
        if #available(iOS 17.0, *) {
            return status == .fullAccess
        } else {
            return status == .authorized
        }
    }
    
    /// 新規イベントを作成
    /// - parameter startDate: 開始日
    /// - parameter endDate: 終了日
    /// - returns: 新規イベント
    func createNewEvent(startDate: Date, endDate: Date) -> EKEvent {
        let newEvent = EKEvent(eventStore: self.eventStore)
        newEvent.startDate = startDate
        newEvent.endDate = endDate
        
        return newEvent
    }
}
