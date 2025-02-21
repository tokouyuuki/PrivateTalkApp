//
//  CalendarViewModel.swift
//  PrivateTalkApp
//
//  Created by 都甲裕希 on 2024/08/22.
//

import Foundation
import EventKit
import SwiftUICore

// MARK: - Calendar ViewModel
@MainActor
final class CalendarViewModel: ObservableObject {
    
    private struct Constants {
        static let FULL_DATE_FORMAT = "yyyy-MM-dd HH:mm:ss"
        static let YEAR_MONTH_DATE_FORMAT_KEY = "year_month_date_format"
        static let PLUS = "+"
    }
    
    // カレンダーのModel
    @Published var monthModels: [MonthModel] = []
    // 表示している月の予定のリスト
    @Published var eventList = [EKEvent]()
    // WorlTimeAPIの世界時刻情報を取得するために使用するService
    private let worldTimeService = WorldTimeService()
    // カレンダーイベントRepository
    private let eventRepository = EventRepository()
    // イベントエラーが発生した際に表示するアラートのタイプ
    @Published var eventErrorAlertType: EventErrorAlertType = .none
    // イベント編集画面を表示するかどうか
    @Published var showEventAddView: Bool = false
    // カレンダーに表示する年月文字列
    @Published var yearMonthString: String = String.empty
    // 選択している日付
    var selectedDate: Date = Date()
    
    // 選択している日付の終了日
    var selectedEndDate: Date {
        // １時間プラスした時刻に変換する
        let newDate = Calendar.current.date(byAdding: DateComponents(hour: 1),
                                            to: self.selectedDate)
        return newDate ?? self.selectedDate
    }
    
    init() {
        Task {
            // カレンダーイベントへのアクセス権限があるか確認
            await self.requestFullAccessToEvents()
            // イベント変更通知の設定
            registerObserver()
            
            let currentDate = Date()
            // MonthModelsをセット
            self.setMonthModels(date: currentDate)
            // 年月文字列をセット
            self.setYearMonthString(currentDate)
        }
    }
    
    // MARK: - Privateメソッド
    
    /// カレンダーイベントへのフルアクセスを要求
    private func requestFullAccessToEvents() async {
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
    
    /// イベント変更通知を監視する設定
    /// 内部または外部からEKEventStoreのイベントに変更があった場合、検知する
    private func registerObserver() {
        NotificationCenter.default.addObserver(forName: .EKEventStoreChanged,
                                               object: nil,
                                               queue: .main) { [weak self] _ in
            guard let self = self else {
                return
            }
            Task { @MainActor in
                self.fetchEvent()
            }
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
        
        self.selectedDate = newDate ?? Date()
    }
    
    /// MonthModelをセット
    /// - parameter date: 指定したい日付
    private func setMonthModels(date: Date) {
        Task {
            let weekModels = await self.getWeekModels(date: date)
            self.monthModels.append(MonthModel(id: date, weekModels: weekModels))
        }
    }
    
    /// １ヶ月分のイベントを取得
    /// - parameter date: 指定したい日付
    private func getWeekModels(date: Date) async -> [WeekModel] {
        let calendar = Calendar.current
        // 開始日、月の日数、月の週数、月の開始日の曜日を取得
        guard let startMonth = calendar.specifiedDay(for: date, at: 1),
              let numberOfDaysInMonth = calendar.daysInMonth(for: date),
              let weeksInMonth = calendar.weeksInMonth(for: date),
              let firstWeekOfMonth = calendar.dayOfWeek(for: startMonth) else {
            return []
        }
        // 最終的にWeekModelsに格納する変数
        var weekModels: [WeekModel] = []
        // WeekModelに格納する日数
        var dayCount:Int = 1
        // 存在する週の数だけ回す
        for week in 1...weeksInMonth {
            // WeekModelに格納する変数
            var dateStrings: [String] = []
            // １週間分の日数を回す
            for dayOfWeekIndex in 1...7 {
                // １週目の日付が存在しない曜日と、最終週の日付が存在しない曜日には空文字を追加
                if (dayOfWeekIndex >= firstWeekOfMonth || week != 1) && dayCount <= numberOfDaysInMonth {
                    dateStrings.append("\(dayCount)")
                } else {
                    dateStrings.append(String.empty)
                    dayCount -= 1
                }
                dayCount += 1
            }
            let eventLabelModels = getEventLabelModels(startMonth: startMonth,
                                                       weekOfMonth: week,
                                                       numberOfDaysInMonth: numberOfDaysInMonth)
            weekModels.append(WeekModel(dateStrings: dateStrings, eventLabelModels: eventLabelModels))
        }
        return weekModels
    }
    
    /// １週間分のイベントを取得
    /// - parameter startMonth: 月の開始日
    /// - parameter weekOfMonth: 月の第何週目
    /// - parameter numberOfDaysInMonth: 月の日数
    /// - returns: [[EventLabelModel]]
    private func getEventLabelModels(startMonth: Date, weekOfMonth: Int, numberOfDaysInMonth: Int) -> [[EventLabelModel]] {
        let calendar = Calendar.current
        // １週間分のイベント✖︎３を格納する変数
        var weeklyLabels: [[EventLabelModel]] = []
        // 週の開始日付(dayOfStartOfWeek)と、週の開始日が何曜日かをindex(startDayOfWeek)で取得
        guard let dayOfStartOfWeek = calendar.dayOfStartOfWeekInMonth(for: startMonth, weekOfMonth: weekOfMonth),
              let startOfWeek = calendar.specifiedDay(for: startMonth, at: dayOfStartOfWeek),
              let startDayOfWeek = calendar.dayOfWeek(for: startOfWeek) else {
            return []
        }
        // １週間のうちの終了日付（第１週目は前月の日付が含まれている場合があるため、それらを取り除く）
        var dayOfEndOfWeek = min(dayOfStartOfWeek + 7 - startDayOfWeek, dayOfStartOfWeek + 6)
        // 最後の週で月の最終日を超えないように調整
        dayOfEndOfWeek = min(dayOfEndOfWeek, numberOfDaysInMonth)
        // １日に表示可能な予定数は３つのためその分For文を回す
        for labelIndex in 0..<3 {
            // １週間分のイベントを格納する変数
            var eventLabelModels: [EventLabelModel] = []
            // 月の始まりの週が日曜日から始まらない場合は予定なしを詰める
            if startDayOfWeek != 1 {
                eventLabelModels.append(EventLabelModel(eventDisplayType: .none,
                                                        eventIdList: [],
                                                        length: startDayOfWeek - 1,
                                                        title: String.empty,
                                                        color: Color.clear))
            }
            // １週間分For文を回す
            for day in dayOfStartOfWeek...dayOfEndOfWeek {
                // １週間のうちの対象日
                guard let targetDate = calendar.specifiedDay(for: startMonth, at: day) else {
                    continue
                }
                // 対象日が含まれるイベントに絞る
                let eventsOfTargetDate = self.filterEvents(for: targetDate)
                // 対象日の１,２,３段目に既に表示することが決まっているイベント
                let displayedEvents = self.filterDisplayedEvents(for: weeklyLabels, by: targetDate)
                // 表示されていないイベントのリスト
                let notDisplayEvents = eventsOfTargetDate.filter { targetEvent in
                    if displayedEvents.isEmpty {
                        return true
                    }
                    return !displayedEvents.contains{ displayEvent in
                        displayEvent.eventIdList.contains { targetEvent.eventIdentifier == $0 }
                    }
                }
                // 表示されていないイベント（表示させる優先度が最も高いイベント）
                guard let highestPriorityEvent = notDisplayEvents.first else {
                    eventLabelModels.append(EventLabelModel(eventDisplayType: .none,
                                                            eventIdList: [],
                                                            length: 1,
                                                            title: String.empty,
                                                            color: Color.clear))
                    continue
                }
                
                // ３列目のラベルを生成する場合
                // かつ対象日にイベントが４つ以上存在する場合
                if labelIndex == 2 && eventsOfTargetDate.count >= 4 {
                    // 前日の３段目のイベントが省略されていなく、そのイベントの期間が対象日も含まれているか確認
                    if let lastEventLabelModel = eventLabelModels.last,
                       let lastEvent = filterEventsMatchingId(id: lastEventLabelModel.eventIdList).first,
                       lastEventLabelModel.eventDisplayType == .full,
                       lastEvent.endDate >= targetDate {
                        // 前日のイベントを非表示にする処理を実施
                        eventLabelModels.removeLast()
                        let element = EventLabelModel(eventDisplayType: .overflow,
                                                      eventIdList: [highestPriorityEvent.eventIdentifier],
                                                      length: 1,
                                                      title: Constants.PLUS + "1",
                                                      color: Color.clear)
                        // イベントの開始日から対象日の日数
                        let hiddenCount = calendar.dateComponents([.day], from: lastEvent.startDate, to: targetDate).day ?? 0
                        eventLabelModels.append(contentsOf: repeatElement(element, count: hiddenCount))
                    }
                    // 対象日の非表示にするイベントID
                    let overEventId: [String] = notDisplayEvents.map { $0.eventIdentifier }
                    // タイトル（"＋非表示のイベント数"）
                    let title = Constants.PLUS + "\(overEventId.count)"
                    eventLabelModels.append(EventLabelModel(eventDisplayType: .overflow,
                                                            eventIdList: overEventId,
                                                            length: 1,
                                                            title: title,
                                                            color: Color.clear))
                    continue
                }
                
                // 対象日と表示するイベントの開始日が同じ日かどうか
                let isSameTargetDayAndStartDay = calendar.isDate(targetDate, inSameDayAs: highestPriorityEvent.startDate)
                // 表示するイベントの日数（開始日は含まれていない）
                let eventDaysBetween = calendar.dateComponents([.day], from: highestPriorityEvent.startDate, to: highestPriorityEvent.endDate).day ?? 0
                
                // 対象日のみのイベントの場合
                if eventDaysBetween == 0 {
                    // ラベルの長さを１とする
                    eventLabelModels.append(EventLabelModel(eventDisplayType: .full,
                                                            eventIdList: [highestPriorityEvent.eventIdentifier],
                                                            length: 1,
                                                            title: highestPriorityEvent.title,
                                                            color: Color(cgColor: highestPriorityEvent.calendar.cgColor)))
                    continue
                }
                
                // イベントが２日以上の場合
                // かつ対象日が開始日のイベント、もしくは週初めの場合
                if isSameTargetDayAndStartDay || dayOfStartOfWeek == day {
                    // イベントが１週間に収まるようにイベントの日数を調整
                    var minEventDaysBetween = min(dayOfEndOfWeek - day, eventDaysBetween)
                    if dayOfStartOfWeek == day {
                        let daysBetween = calendar.dateComponents([.day], from: targetDate, to: highestPriorityEvent.endDate).day ?? 0
                        minEventDaysBetween = min(dayOfEndOfWeek - day, daysBetween)
                    }
                    
                    // 週初めにイベントが終了日、もしくは週の最終日にイベントが開始日の場合、この後の処理は行わない
                    if minEventDaysBetween == 0 {
                        eventLabelModels.append(EventLabelModel(eventDisplayType: .full,
                                                                eventIdList: [highestPriorityEvent.eventIdentifier],
                                                                length: 1,
                                                                title: highestPriorityEvent.title,
                                                                color: Color(cgColor: highestPriorityEvent.calendar.cgColor)))
                        continue
                    }
                    
                    // 表示するイベントの日数分For文を回す
                    for dayOffset in 1...minEventDaysBetween {
                        // 他の日を確認し、表示しようとしているイベントより優先するイベントがある場合は、優先度を調整する
                        if let nextDay = calendar.specifiedDay(for: highestPriorityEvent.startDate, at: day + dayOffset) {
                            // 対象日が含まれるイベントに絞る
                            let eventsOfTargetDate = self.filterEvents(for: nextDay)
                            // 対象日の１,２,３段目に既に表示されているイベント
                            let nextDisplayedEvents = self.filterDisplayedEvents(for: weeklyLabels, by: nextDay)
                            
                            // 表示されていないイベント（表示させる優先度の高いイベント）
                            if let notNextDisplayEvents = eventsOfTargetDate.first(where: { targetEvent in
                                if nextDisplayedEvents.isEmpty {
                                    return true
                                }
                                return !nextDisplayedEvents.contains{ displayEvent in
                                    displayEvent.eventIdList.contains { targetEvent.eventIdentifier == $0 }
                                }
                            }) {
                                // 表示するイベントと次の日のイベントが異なる場合
                                if highestPriorityEvent.eventIdentifier != notNextDisplayEvents.eventIdentifier {
                                    // 表示可能なイベントを抽出
                                    if let newDisplayEvent = notDisplayEvents.first(where: {
                                        let newDaysBetween = calendar.dateComponents([.day], from: $0.startDate, to: $0.endDate).day ?? 0
                                        return newDaysBetween < dayOffset
                                    }) {
                                        let newDaysBetween = calendar.dateComponents([.day], from: newDisplayEvent.startDate, to: newDisplayEvent.endDate).day ?? 0
                                        eventLabelModels.append(EventLabelModel(eventDisplayType: .full,
                                                                                eventIdList: [newDisplayEvent.eventIdentifier],
                                                                                length: newDaysBetween + 1,
                                                                                title: newDisplayEvent.title,
                                                                                color: Color(cgColor: newDisplayEvent.calendar.cgColor)))
                                    } else {
                                        eventLabelModels.append(EventLabelModel(eventDisplayType: .none,
                                                                                eventIdList: [],
                                                                                length: 1,
                                                                                title: String.empty,
                                                                                color: Color.clear))
                                    }
                                    break
                                }
                            }
                        }
                        
                        // 特に優先するイベントがない場合
                        if dayOffset == minEventDaysBetween {
                            eventLabelModels.append(EventLabelModel(eventDisplayType: .full,
                                                                    eventIdList: [highestPriorityEvent.eventIdentifier],
                                                                    length: minEventDaysBetween + 1,
                                                                    title: highestPriorityEvent.title,
                                                                    color: Color(highestPriorityEvent.calendar.cgColor)))
                            break
                        }
                    }
                }
            }
            weeklyLabels.append(eventLabelModels)
        }
        return weeklyLabels
    }
    
    /// 指定の日付を元にイベントをフィルタリングする
    /// - parameter date: 対象日
    /// - returns: フィルタリングされたイベント
    private func filterEvents(for date: Date) -> [EKEvent] {
        let calendar = Calendar.current
        return self.eventList.filter {
            let startOfStartDay = calendar.startOfDay(for: $0.startDate)
            return startOfStartDay <= date && date <= $0.endDate
        }.sorted {
            // 1. 期間が長いイベントを優先する
            let firstDurationEvent = $0.endDate.timeIntervalSince($0.startDate)
            let secondDurationEvent = $1.endDate.timeIntervalSince($1.startDate)
            if firstDurationEvent != secondDurationEvent {
                return firstDurationEvent > secondDurationEvent
            }
            // 2. 終日のイベントを優先する
            if $0.isAllDay != $1.isAllDay {
                return $0.isAllDay && !$1.isAllDay
            }
            // 3. 開始日が早いものを優先する
            return $0.startDate < $1.startDate
        }
    }
    
    /// 指定の日付を元に、表示することが決まっているイベントにフィルタリングする
    /// - parameter weeklyLabels: １週間分の表示するイベント
    /// - parameter date: 対象日
    /// - returns: [EventLabelModel]
    private func filterDisplayedEvents(for weeklyLabels: [[EventLabelModel]], by date: Date) -> [EventLabelModel] {
        let calendar = Calendar.current
        return weeklyLabels.flatMap { eventLabelModels in
            eventLabelModels.filter { eventLabelModel in
                // モデルに格納されているものからイベントを取得
                if let displayedEvent = filterEventsMatchingId(id: eventLabelModel.eventIdList).first,
                   eventLabelModel.eventDisplayType == .full {
                    // そのイベントが指定された期間内かを判定
                    let startOfStartDay = calendar.startOfDay(for: displayedEvent.startDate)
                    return startOfStartDay <= date && date <= displayedEvent.endDate
                }
                return false
            }
        }
    }
    
    /// IDと一致するイベントにフィルタリングする
    /// - parameter id: フィルタリングしたいIDのリスト
    /// - returns: フィルタリングされたイベント
    private func filterEventsMatchingId(id: [String]) -> [EKEvent] {
        return self.eventList.filter {
            return id.contains($0.eventIdentifier)
        }
    }
    
    // MARK: - Publicメソッド
    /// 年月文字列をセット
    /// - parameter date: セットしたいDate
    func setYearMonthString(_ date: Date?) {
        let yearMonthString = DateUtilities.convertDateToString(date: date,
                                                                format: Constants.YEAR_MONTH_DATE_FORMAT_KEY)
        self.yearMonthString = yearMonthString ?? String.empty
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
    
    /// イベントを取得
    func fetchEvent() {
        do {
            let addMonth = DateComponents(month: 1, day: -1)
            // 月の開始日と終了日を取得
            guard let firstDay = Calendar.current.specifiedDay(for: self.selectedDate, at: 1),
                  let lastDay = Calendar.current.date(byAdding: addMonth, to: firstDay) else {
                return
            }
            self.eventList = try eventRepository.fetchEvent(startDate: firstDay, endDate: lastDay)
        } catch let eventError {
            Logger().log(eventError.errorDescription ?? String.empty, level: .error)
            self.eventErrorAlertType = .init(error: eventError)
        }
    }
    
    /// イベント追加ボタンを押下時の処理
    func onTapAddEventView() {
        // カレンダーイベントへのアクセス権限があるか確認
        if EventStoreManager.shared.isFullAccessToEvents() {
            // 権限がある場合は、EventAddViewを表示
            self.showEventAddView = true
        } else {
            self.eventErrorAlertType = .init(error: .notAccess)
        }
    }
}
