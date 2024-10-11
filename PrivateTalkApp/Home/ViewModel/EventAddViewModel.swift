//
//  EventAddViewModel.swift
//  PrivateTalkApp
//
//  Created by 都甲裕希 on 2024/10/11.
//

import Foundation

// MARK: - 予定追加 ViewModel
@MainActor
final class EventAddViewModel: ObservableObject {
    
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
        self.startDate = startDate
        self.endDate = endDate
    }
    
    // 予定の編集が行われたかどうか
    var isEditedEvent: Bool {
        return self.isAllDay
        // TODO: startDate、endDateも付け加える
        || !self.titleText.isEmpty
        || !self.placeText.isEmpty
        || !self.urlText.isEmpty
        || !self.memoText.isEmpty
    }
}
