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
    }
    
    // カレンダーのModel
    @MainActor @Published var weekModelList: [WeekModel] = []
    // 表示している月の予定のリスト
    @Published var eventList = [EKEvent]()
    // WorlTimeAPIの世界時刻情報を取得するために使用するService
    private let worldTimeService = WorldTimeService()
    // カレンダーイベントRepository
    private let eventRepository = EventRepository()
    // イベントエラーが発生した際に表示するアラートのタイプ
    @MainActor @Published var eventErrorAlertType: EventErrorAlertType = .none
    // イベント編集画面を表示するかどうか
    @MainActor @Published var showEventAddView: Bool = false
    // カレンダーに表示する年月文字列
    @MainActor @Published var yearMonthString: String = String.empty
    // 選択している日付
    @MainActor var selectedDate: Date = Date()
    
    // 選択している日付の終了日
    @MainActor var selectedEndDate: Date {
        // １時間プラスした時刻に変換する
        let newDate = Calendar.current.date(byAdding: DateComponents(hour: 1),
                                            to: self.selectedDate)
        return newDate ?? self.selectedDate
    }
    
    init() {
        // イベント変更通知の設定
        registerObserver()
        
        let calendar = Calendar.current
        let currentDate = Date()
        // 今月の開始日、今月の日数、今月の週数、今月の開始日の曜日を取得
        guard let startMonth = calendar.startOfMonth(for: currentDate),
              let daysInMonth = calendar.daysInMonth(for: currentDate),
              let weeksInMonth = calendar.weeksInMonth(for: currentDate),
              let firstWeekOfMonth = calendar.firstWeekOfMonth(for: startMonth) else {
            return
        }
        // WeekModelListをセット
        self.setWeekModelList(daysInMonth: daysInMonth,
                              weeksInMonth: weeksInMonth,
                              firstWeekOfMonth: firstWeekOfMonth)
        // 年月文字列をセット
        self.setYearMonthString(startMonth)
        // カレンダーイベントへのアクセス権限があるか確認
        self.requestFullAccessToEvents()
    }
    
    // MARK: - Privateメソッド
    /// 年月文字列をセット
    /// - parameter date: セットしたいDate
    private func setYearMonthString(_ date: Date?) {
        Task { @MainActor in
            let yearMonthString = DateUtilities.convertDateToString(date: date,
                                                                    format: Constants.YEAR_MONTH_DATE_FORMAT_KEY)
            self.yearMonthString = yearMonthString ?? String.empty
        }
    }
    
    /// イベント変更通知を監視する設定
    /// 内部または外部からEKEventStoreのイベントに変更があった場合、検知する
    private func registerObserver() {
        NotificationCenter.default.addObserver(forName: .EKEventStoreChanged,
                                               object: nil,
                                               queue: .main) { [weak self] _ in
            guard let self = self else {
                return
            }
            self.fetchEvent()
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
                                    minute: 0,
                                    second: 0,
                                    of: date)
        
        Task { @MainActor in
            self.selectedDate = newDate ?? Date()
        }
    }
    
    /// WeekModelListをセット
    /// - parameter daysInMonth: 月の日数
    /// - parameter weeksInMonth: 月の週数
    /// - parameter firstWeekOfMonth: 月の開始日の曜日index
    private func setWeekModelList(daysInMonth: Int, weeksInMonth: Int, firstWeekOfMonth: Int) {
        Task { @MainActor in
            // 最終的にWeekModelListに格納する変数
            var weekModelList: [WeekModel] = []
            // WeekModelに格納する日数
            var dayCount:Int = 1
            // 存在する週の数だけ回す
            for week in 1...weeksInMonth {
                // WeekModelに格納する変数
                var dateStringList: [String] = []
                // １週間分の日数を回す
                for dayOfWeekIndex in 1...7 {
                    // １週目の日付が存在しない曜日と、最終週の日付が存在しない曜日には空文字を追加
                    if (dayOfWeekIndex >= firstWeekOfMonth || week != 1) && dayCount <= daysInMonth {
                        dateStringList.append("\(dayCount)")
                    } else {
                        dateStringList.append(String.empty)
                        dayCount -= 1
                    }
                    dayCount += 1
                }
                weekModelList.append(WeekModel(dateStringList: dateStringList))
            }
            
            self.weekModelList = weekModelList
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
                    self.eventErrorAlertType = .init(error: .notAccess)
                }
            } catch {
                Logger().log(error.localizedDescription, level: .error)
                self.eventErrorAlertType = .init(error: .unexpected)
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
                self.setYearMonthString(currentUtcDate)
            } catch {
                // UTCかつ端末に依存する今日の日付をセットする
                self.setYearMonthString(Date())
                guard let networkError = error as? NetworkError else {
                    return
                }
                Logger().log(networkError.errorDescription ?? String.empty, level: .error)
            }
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
        // TODO: 後ほど
//        Task { @MainActor in
//            do {
//                let subtract = DateComponents(month: -1)
//                let addMonth = DateComponents(month: 2)
//                guard let thisMonth = self.calendarModel?.displayDate,
//                      let startDate = Calendar.current.date(byAdding: subtract, to: thisMonth),
//                      let endDate = Calendar.current.date(byAdding: addMonth, to: thisMonth) else {
//                    return
//                }
//                self.eventList = try eventRepository.fetchEvent(startDate: startDate, endDate: endDate)
//                notifyCalendarView()
//            } catch let eventError as EventError {
//                Logger().log(eventError.errorDescription ?? String.empty, level: .error)
//                self.eventErrorAlertType = .init(error: eventError)
//            }
//        }
    }
    
    /// イベント追加ボタンを押下時の処理
    func onTapAddEventView() {
        Task { @MainActor in
            // カレンダーイベントへのアクセス権限があるか確認
            if EventStoreManager.shared.isFullAccessToEvents() {
                // 権限がある場合は、EventAddViewを表示
                self.showEventAddView = true
            } else {
                self.eventErrorAlertType = .init(error: .notAccess)
            }
        }
    }
}
