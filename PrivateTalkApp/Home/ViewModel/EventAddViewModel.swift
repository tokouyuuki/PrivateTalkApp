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
    
    // 予定
    private let event: EKEvent
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
    
    /// - parameter selectedStartDate: カレンダーで選択している日付（開始日）
    /// - parameter selectedEndDate: カレンダーで選択している日付（終了日）
    init(startDate: Date, endDate: Date) {
        // 新規予定を作成
        let event = EventStoreManager.shared.createNewEvent(startDate: startDate,
                                                            endDate: endDate)
        self.event = event
        self.startDate = event.startDate
        self.endDate = event.endDate
    }
    
    // 予定の編集が行われたかどうか
    var isEditedEvent: Bool {
        return self.isAllDay
        || self.startDate != self.event.startDate
        || self.endDate != self.event.endDate
        || !self.titleText.isEmpty
        || !self.placeText.isEmpty
        || !self.urlText.isEmpty
        || !self.memoText.isEmpty
    }
}
