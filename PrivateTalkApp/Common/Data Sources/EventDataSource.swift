//
//  EventDataSource.swift
//  PrivateTalkApp
//
//  Created by 都甲裕希 on 2024/10/04.
//

import Foundation
import EventKit

// MARK: - イベント（カレンダーイベントやリマインダー）の取得・保存などの操作を管理するデータソースクラス
struct EventDataSource {
    
    /// カレンダーにイベントを保存する
    /// - parameter event: イベント
    func saveEvent(_ event: EKEvent) async throws {
        try await Task {
            try EventStoreManager.shared.eventStore.save(event, span: .thisEvent, commit: true)
        }.value
    }
}
