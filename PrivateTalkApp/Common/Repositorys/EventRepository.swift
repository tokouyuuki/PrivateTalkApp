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
}
