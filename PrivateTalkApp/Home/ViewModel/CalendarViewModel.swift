//
//  CalendarViewModel.swift
//  PrivateTalkApp
//
//  Created by 都甲裕希 on 2024/08/22.
//

import Foundation

// MARK: - Calendar ViewModel
@MainActor
final class CalendarViewModel: ObservableObject {
    
    private struct Constants {
        static let FULL_DATE_FORMAT = "yyyy-MM-dd HH:mm:ss"
        static let YEAR_MONTH_DATE_FORMAT_KEY = "year_month_date_format"
        static let SELECTED_END_DATE_ADD_HOUR = 1
        static let SELECTED_DATE_MINUTE = 0
        static let SELECTED_DATE_SECOND = 0
    }
    
    // カレンダーのModel
    @Published var calendarModel: CalendarModel?
    // WorlTimeAPIの世界時刻情報を取得するために使用するService
    private let worldTimeService = WorldTimeService()
    // 選択している日付
    var selectedDate: Date = Date()
    
    // 選択している日付の終了日
    var selectedEndDate: Date {
        // １時間プラスした時刻に変換する
        let newDate = Calendar.current.date(byAdding: DateComponents(hour: Constants.SELECTED_END_DATE_ADD_HOUR),
                                            to: self.selectedDate)
        return newDate ?? self.selectedDate
    }
    
    // MARK: - Privateメソッド
    /// 年月文字列をセット
    /// - parameter date: セットしたいDate
    private func setDisplayDate(_ date: Date?) {
        Task { [weak self] in
            guard let self = self else {
                return
            }
            self.calendarModel = CalendarModel(date: date)
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
        
        self.selectedDate = newDate ?? Date()
    }
    
    // MARK: - Publicメソッド
    /// カレンダーイベントへのフルアクセスを要求
    func requestFullAccessToEvents() {
        Task {
            if #available(iOS 17.0, *) {
                do {
                    try await EventStoreManager.shared.eventStore.requestFullAccessToEvents()
                } catch {
                    Logger().log(error.localizedDescription, level: .error)
                }
            } else {
                do {
                    try await EventStoreManager.shared.eventStore.requestAccess(to: .event)
                } catch {
                    Logger().log(error.localizedDescription, level: .error)
                }
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
                guard let networkError = error as? NetworkError else {
                    return
                }
                Logger().log(networkError.errorDescription, level: .error)
            }
        }
    }
    
    /// 年月がCalendarModelと一致しているかどうか
    /// - parameter dateToCompare: 比較したいDate
    /// - returns: 一致すればtrue / 一致しなければfalse
    func isMatchedDate(dateToCompare: Date) -> Bool {
        // 比較したい年月
        let dateToCompareString = DateUtilities.convertDateToString(date: dateToCompare, format: Constants.YEAR_MONTH_DATE_FORMAT_KEY)
        
        return dateToCompareString == self.calendarModel?.displayYearMonthString
    }
    
    /// 日付の更新をする
    /// - parameter eventAction: 更新する値を決めるenum
    func updateDate(_ eventAction: EventAction) {
        switch eventAction {
        case .updateDisplayDate(let date):
            self.setDisplayDate(date)
        case .updateSelectedDate(let date):
            self.setSelectedDate(date)
        }
    }
}
