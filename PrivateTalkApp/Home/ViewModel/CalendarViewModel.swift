//
//  CalendarViewModel.swift
//  PrivateTalkApp
//
//  Created by 都甲裕希 on 2024/08/22.
//

import Foundation
import EventKit

// MARK: - Calendar ViewModel
final class CalendarViewModel: ObservableObject {
    
    private struct Constants {
        static let FULL_DATE_FORMAT = "yyyy-MM-dd HH:mm:ss"
        static let YEAR_MONTH_DATE_FORMAT_KEY = "year_month_date_format"
        static let SELECTED_END_DATE_ADD_HOUR = 1
        static let SELECTED_DATE_MINUTE = 0
        static let SELECTED_DATE_SECOND = 0
        static let ADD_MONTH = 2
        static let SUBTRACT_MONTH = -1
    }
    
    // カレンダーのModel
    @MainActor @Published var calendarModel: CalendarModel?
    // 表示している月の予定のリスト
    @Published var eventList = [EKEvent]()
    // エラーダイアログを表示するかどうか
    @MainActor @Published var showErrorDialog = false
    // WorlTimeAPIの世界時刻情報を取得するために使用するService
    private let worldTimeService = WorldTimeService()
    // カレンダーイベントRepository
    private let eventRepository = EventRepository()
    // エラーが発生した際に使用する変数
    @MainActor var error: PrivateTalkAppError?
    // 選択している日付
    @MainActor var selectedDate: Date = Date()
    
    // 選択している日付の終了日
    @MainActor var selectedEndDate: Date {
        // １時間プラスした時刻に変換する
        let newDate = Calendar.current.date(byAdding: DateComponents(hour: Constants.SELECTED_END_DATE_ADD_HOUR),
                                            to: self.selectedDate)
        return newDate ?? self.selectedDate
    }
    
    // MARK: - Privateメソッド
    /// 年月文字列をセット
    /// - parameter date: セットしたいDate
    private func setDisplayDate(_ date: Date?) {
        Task { @MainActor [weak self] in
            guard let self = self else {
                return
            }
            self.calendarModel = CalendarModel(date: date)
        }
    }
    
    /// CalendarViewに再描画を行うよう通知
    /// UIViewRepresentableを使用すると、カレンダーセル構築とイベント取得のタイミングがコントロールできない。
    /// そのため、イベントを取得したタイミングで通知を送信する。
    private func notifyCalendarView() {
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: Notification.Name("calendarReload"), object: nil)
        }
    }
    
    /// カレンダーで選択した日付をセット
    /// - parameter date: 選択したDate
    private func setSelectedDate(_ date: Date) {
        let calendar = Calendar.current
        // 現在の時間を抽出
        guard let currentHourComponent = calendar.dateComponents([.hour], from: Date()).hour else {
            return
        }
        // 分、秒を切り捨て現在の時間にし、キリが良い時刻に変換する
        let newDate = calendar.date(bySettingHour: currentHourComponent,
                                    minute: Constants.SELECTED_DATE_MINUTE,
                                    second: Constants.SELECTED_DATE_SECOND,
                                    of: date)
        
        Task { @MainActor in
            self.selectedDate = newDate ?? Date()
        }
    }
    
    // MARK: - Publicメソッド
    /// カレンダーイベントへのフルアクセスを要求
    func requestFullAccessToEvents() {
        Task { @MainActor in
            do {
                let isFullAccess = try await EventStoreManager.shared.eventStore.requestFullAccessToEvents()
                if isFullAccess {
                    fetchEvent()
                } else {
                    notifyCalendarView()
                    self.error = PrivateTalkAppError.eventError(.notAccess)
                    self.showErrorDialog = true
                }
            } catch {
                Logger().log(error.localizedDescription, level: .error)
                self.error = PrivateTalkAppError.unexpected
                self.showErrorDialog = true
            }
        }
    }
    
    /// 今日ボタンを押下された際の処理
    func tapTodayButton() {
        Task {
            do {
                // 現在の時刻をUTC文字列で取得
                let datetime = try await self.worldTimeService.fetchWorldTime()
                // UTC文字列をUTCのDateに変換
                let currentUtcDate = DateUtilities.convertStringToUtcDate(dateString: datetime,
                                                                          format: Constants.FULL_DATE_FORMAT)
                // UTCのDateからローカルタイムゾーンの年月文字列をセットする
                self.setDisplayDate(currentUtcDate)
            } catch {
                // UTCかつ端末に依存する今日の日付をセットする
                self.setDisplayDate(Date())
                guard let privateTalkAppError = error as? PrivateTalkAppError else {
                    return
                }
                Logger().log(privateTalkAppError.errorDescription ?? String.empty, level: .error)
            }
        }
    }
    
    /// 年月がCalendarModelと一致しているかどうか
    /// - parameter dateToCompare: 比較したいDate
    /// - returns: 一致すればtrue / 一致しなければfalse
    @MainActor
    func isMatchedDate(dateToCompare: Date) -> Bool {
        // 比較したい年月
        let dateToCompareString = DateUtilities.convertDateToString(date: dateToCompare, format: Constants.YEAR_MONTH_DATE_FORMAT_KEY)
        
        return dateToCompareString == self.calendarModel?.displayYearMonthString
    }
    
    /// アクションによって処理を行う
    /// - parameter eventAction: アクション
    func handleAction(_ eventAction: EventAction) {
        switch eventAction {
        case .updateDisplayDate(let date):
            self.setDisplayDate(date)
        case .updateSelectedDate(let date):
            self.setSelectedDate(date)
        case .requestFullAccessToEvents:
            self.requestFullAccessToEvents()
        case .fetchEvent:
            self.fetchEvent()
        }
    }
    
    /// 日付に対するイベントのリストを取得
    /// - parameter date: 取得したいタイトルの日付
    /// - returns: イベントのリスト
    func getEventList(date: Date) -> [EKEvent] {
        let calendar = Calendar.current
        let eventList = eventList.filter {
            calendar.isDate($0.startDate, inSameDayAs: date)
        }.sorted(by: { (a, b) -> Bool in
            return a.startDate < b.startDate
        })
        
        return eventList
    }
    
    /// イベントを取得
    func fetchEvent() {
        Task { @MainActor in
            do {
                let subtract = DateComponents(month: Constants.SUBTRACT_MONTH)
                let addMonth = DateComponents(month: Constants.ADD_MONTH)
                guard let thisMonth = self.calendarModel?.displayDate,
                      let startDate = Calendar.current.date(byAdding: subtract, to: thisMonth),
                      let endDate = Calendar.current.date(byAdding: addMonth, to: thisMonth) else {
                    return
                }
                self.eventList = try await eventRepository.fetchEvent(startDate: startDate, endDate: endDate)
                notifyCalendarView()
            } catch {
                guard let privateTalkAppError = error as? PrivateTalkAppError else {
                    return
                }
                Logger().log(privateTalkAppError.errorDescription ?? String.empty, level: .error)
            }
        }
    }
    
    /// エラーをリセットする
    /// "error"と"showErrorDialog"を使う導線がある場合、最終的にこのメソッドを呼ばないといけない
    func resetError() {
        Task { @MainActor in
            self.error = nil
            self.showErrorDialog = false
        }
    }
}
