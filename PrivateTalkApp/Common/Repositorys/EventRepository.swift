//
//  EventRepository.swift
//  PrivateTalkApp
//
//  Created by 都甲裕希 on 2024/10/15.
//

import Foundation
import EventKit

// MARK: - カレンダーイベントのRepository
struct EventRepository {
    
    private let eventDataSource = EventDataSource()
    
    /// イベントを追加する
    /// - parameter event: イベント
    func addEvent(event: EKEvent) throws(EventError) {
        do {
            if !EventStoreManager.shared.isFullAccessToEvents() {
                throw EventError.notAccess
            }
            try eventDataSource.saveEvent(event)
        } catch {
            throw EventError.saveFailed
        }
    }
    
    /// イベントを取得する
    /// - parameter startDate: 取得したいイベントの開始日
    /// - parameter endDate: 取得したいイベントの終了日
    func fetchEvent(startDate: Date, endDate: Date) throws(EventError) -> [EKEvent] {
        if !EventStoreManager.shared.isFullAccessToEvents() {
            throw EventError.notAccess
        }
        let predicate = EventStoreManager.shared.eventStore.predicateForEvents(withStart: startDate,
                                                                               end: endDate,
                                                                               calendars: nil)
        return eventDataSource.fetchEvent(predicate: predicate)
    }
}
