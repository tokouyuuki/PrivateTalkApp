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
    
    // 開始日の初期値
    private let initialStartDate: Date
    // 終了日の初期値
    private let initialEndDate: Date
    // カレンダーイベントRepository
    private let eventRepository = EventRepository()
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
    // エラーが発生した際に使用する変数
    var error: PrivateTalkAppError?
    // 予定の保存が成功したかどうか
    @Published var isSavedEventSuccessfully = false
    // 予定の保存が失敗したかどうか
    @Published var showErrorDialog = false
    
    /// - parameter startDate: カレンダーで選択している日付（開始日）
    /// - parameter endDate: カレンダーで選択している日付（終了日）
    init(startDate: Date, endDate: Date) {
        self.initialStartDate = startDate
        self.initialEndDate = endDate
        self.startDate = startDate
        self.endDate = endDate
    }
    
    // 予定の編集が行われたかどうか
    var isEditedEvent: Bool {
        return self.isAllDay
        || self.startDate != self.initialStartDate
        || self.endDate != self.initialEndDate
        || !self.titleText.isEmpty
        || !self.placeText.isEmpty
        || !self.urlText.isEmpty
        || !self.memoText.isEmpty
    }
    
    /// 予定を追加する
    func addEvent() {
        Task {
            do {
                // 入力値を元に、新規予定を作成
                let event = EventStoreManager.shared.createNewEvent(startDate: self.startDate,
                                                                    endDate: self.endDate,
                                                                    title: self.titleText,
                                                                    isAllDay: self.isAllDay,
                                                                    notes: self.memoText)
                // 予定を追加
                try await eventRepository.addEvent(event: event)
                self.isSavedEventSuccessfully = true
            } catch let privateTalkAppError as PrivateTalkAppError {
                self.error = privateTalkAppError
                self.showErrorDialog = true
            } catch {
                Logger().log(error.localizedDescription, level: .error)
            }
        }
    }
    
    /// エラーをリセットする
    /// "error"と"showErrorDialog"を使う導線がある場合、最終的にこのメソッドを呼ばないといけない
    func resetError() {
        self.error = nil
        self.showErrorDialog = false
    }
}
