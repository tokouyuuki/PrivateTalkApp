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
    func addEvent(event: EKEvent) async throws(PrivateTalkAppError) {
        do {
            if !EventStoreManager.shared.isFullAccessToEvents() {
                throw PrivateTalkAppError.eventError(.notAccess)
            }
            try await eventDataSource.saveEvent(event)
        } catch {
            throw PrivateTalkAppError.eventError(.saveFailed)
        }
    }
    
    /// イベントを取得する
    /// - parameter startDate: 取得したいイベントの開始日
    /// - parameter endDate: 取得したいイベントの終了日
    func fetchEvent(startDate: Date, endDate: Date) async throws(PrivateTalkAppError) -> [EKEvent] {
        if !EventStoreManager.shared.isFullAccessToEvents() {
            throw PrivateTalkAppError.eventError(.notAccess)
        }
        let predicate = EventStoreManager.shared.eventStore.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)
        return await eventDataSource.fetchEvent(predicate: predicate)
    }
}
