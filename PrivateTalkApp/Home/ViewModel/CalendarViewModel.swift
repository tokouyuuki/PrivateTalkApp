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
        static let YEAR_MONTH_DATE_FORMAT_KEY = "year_month_date_format"
        static let PLUS = "+"
    }
    
    // 月のModel
    @Published var monthModels: [MonthModel] = []
    // 現在表示中の月のID
    @Published var selectedCalendarID: String = String.empty
    // ボタンが無効かどうか（有効(true): 今日ボタン押せない ／ 無効(false): 今日ボタン押せる）
    @Published var isTodayButtonDisabled: Bool = false
    // イベントエラーが発生した際に表示するアラートのタイプ
    @Published var eventErrorAlertType: EventErrorAlertType = .none
    // イベント編集画面を表示するかどうか
    @Published var showEventAddView: Bool = false
    // カレンダーイベントRepository
    private let eventRepository = EventRepository()
    // 表示している月の予定のリスト
    private var events = [EKEvent]()
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
        self.setup()
    }
    
    // MARK: - Privateメソッド
    /// 初期設定
    private func setup() {
        Task {
            // カレンダーイベントへのアクセス権限があるか確認
            if await self.requestFullAccessToEvents() {
                // 今月のイベントを取得
                self.events = fetchEvent(referenceMonthForEvents: Date(),
                                         monthOffset: 0)
            }
            // 今月のMonthModelを生成
            if let monthModel = await self.createMonthModel(date: Date(),
                                                            monthOffset: 0) {
                self.monthModels.append(monthModel)
            }
            // イベント変更通知の設定
            registerObserver()
        }
    }
    
    /// カレンダーイベントへのフルアクセスを要求
    private func requestFullAccessToEvents() async -> Bool {
        do {
            let isFullAccess = try await EventStoreManager.shared.eventStore.requestFullAccessToEvents()
            if !isFullAccess {
                self.eventErrorAlertType = .init(error: .notAccess)
            }
            return isFullAccess
        } catch {
            Logger().log(error.localizedDescription, level: .error)
            self.eventErrorAlertType = .init(error: .unexpected)
            return false
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
                // TODO: 後ほど修正
//                self.fetchEvent(referenceMonthForEvents: Date(),
//                                monthOffset: 0)
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
    
    /// １ヶ月分の月モデルを生成
    /// - parameter date: 基準となる月
    /// - parameter monthOffset: 基準月からのオフセット（基準値からの数ヶ月前（または後））
    private func createMonthModel(date: Date, monthOffset: Int) async -> MonthModel? {
        // 生成するモデルの月
        guard let targetMonth = Calendar.current.date(byAdding: DateComponents(month: monthOffset), to: date) else {
            return nil
        }
        let yearMonthString = DateUtilities.convertDateToString(date: targetMonth,
                                                                format: Constants.YEAR_MONTH_DATE_FORMAT_KEY) ?? String.empty
        // 今月のデータを生成している場合は、カレンダーのIDをセット（初回のみこの処理は実行される）
        if monthOffset == 0 {
            self.selectedCalendarID = yearMonthString
        }
        let weekModels = self.createWeekModels(date: targetMonth)
        return MonthModel(yearMonthString: yearMonthString,
                          weekModels: weekModels)
    }
    
    /// １ヶ月分の週モデルを生成
    /// - parameter date: 対象の月
    private func createWeekModels(date: Date) -> [WeekModel] {
        let calendar = Calendar.current
        // 開始日、月の日数を取得
        guard let startMonth = calendar.specifiedDay(for: date, at: 1),
              let numberOfDaysInMonth = calendar.daysInMonth(for: date) else {
            return []
        }
        
        var dateStrings: [String] = []
        // １ヶ月分の日数
        return (1...numberOfDaysInMonth).compactMap { dayOffset in
            // 月の開始日が日曜日から始まらない場合
            if startMonth.dayOfWeek != 1 && dayOffset == 1 {
                // １週目の日付が存在しない曜日には空文字を追加
                let emptyStrings = Array(repeating: String.empty,
                                         count: startMonth.dayOfWeek - 1)
                dateStrings.append(contentsOf: emptyStrings)
            }
            
            dateStrings.append(String(dayOffset))
            // １週間ごとにリターン
            if dateStrings.count % 7 == 0 {
                let eventLabelModel = createEventLabelModel(startMonth: startMonth,
                                                            displaydays: dateStrings.suffix(7))
                return WeekModel(displaydays: dateStrings.suffix(7),
                                 eventLabelModel: eventLabelModel)
            }
            // 最終週が土曜日で終わらない時は、日数を計算してリターン
            if dayOffset == numberOfDaysInMonth {
                let daysInFinalWeek = Int(dateStrings.count % 7)
                let eventLabelModel = createEventLabelModel(startMonth: startMonth,
                                                            displaydays: dateStrings.suffix(daysInFinalWeek))
                return WeekModel(displaydays: dateStrings.suffix(daysInFinalWeek),
                                 eventLabelModel: eventLabelModel)
            }
            return nil
        }
    }
    
    /// １週間分のイベントを取得
    /// - parameter startMonth: 月の開始日
    /// - parameter displaydays: １週間分の日数
    /// - returns: [[EventLabelModel]]
    private func createEventLabelModel(startMonth: Date, displaydays: [String]) -> [[EventLabelModel]] {
        let calendar = Calendar.current
        // １週間分のイベント✖︎３を格納する変数
        var weekEventColumns: [[EventLabelModel]] = []
        // １週間の日付
        let weekDays = displaydays.filter { !$0.isEmpty }.compactMap { Int($0) }
        // １週間のうち日付が存在しない
        let weekEmpty = displaydays.filter { $0.isEmpty }
        // １日に表示可能な予定数は３つのためその分For文を回す
        for labelIndex in 0..<3 {
            // １週間分のイベントを格納する変数
            var eventLabelModels: [EventLabelModel] = []
            // 月の始まりの週が日曜日から始まらない場合は予定なしを詰める
            if !weekEmpty.isEmpty {
                eventLabelModels.append(EventLabelModel(eventDisplayType: .none,
                                                        eventIdList: [],
                                                        length: weekEmpty.count,
                                                        title: String.empty,
                                                        color: Color.clear))
            }
            // １週間分For文を回す
            for day in weekDays {
                // １週間のうちの対象日
                guard let targetDate = calendar.specifiedDay(for: startMonth, at: day) else {
                    continue
                }
                // 対象日が含まれるイベントに絞る
                let eventsOfTargetDate = self.filterEvents(for: targetDate)
                // 表示されていないイベントのリスト
                let notDisplayEvents = self.filterNotDisplayEvents(excluding: weekEventColumns,
                                                                   from: eventsOfTargetDate)
                // 表示されていないイベント（表示させる優先度が最も高いイベント）
                guard let highestPriorityEvent = self.getHighestPriorityEvent(notDisplayEvents: notDisplayEvents,
                                                                              lastEventLabelModel: eventLabelModels.last,
                                                                              targetDay: day) else {
                    eventLabelModels.append(EventLabelModel(eventDisplayType: .none,
                                                            eventIdList: [],
                                                            length: 1,
                                                            title: String.empty,
                                                            color: Color.clear))
                    continue
                }
                // ３列目のラベルを生成する場合
                if labelIndex == 2 {
                    // 対象日にイベントが４つ以上存在する場合
                    if eventsOfTargetDate.count >= 4 {
                        let overflowLabelsForPastEvents = self.createOverflowLabelsForPastEventsIfNeeded(lastEventLabelModel: eventLabelModels.last,
                                                                                                         highestPriorityEventId: highestPriorityEvent.eventIdentifier)
                        if !overflowLabelsForPastEvents.isEmpty {
                            eventLabelModels.removeLast()
                            eventLabelModels.append(contentsOf: overflowLabelsForPastEvents)
                        }
                        eventLabelModels.append(self.createOverflowEventLabel(notDisplayEvents: notDisplayEvents))
                        continue
                    }
                    // 前日の非表示イベントに、対象イベントが含まれる場合
                    if let lastEventLabelModel = eventLabelModels.last,
                       lastEventLabelModel.eventDisplayType == .overflow,
                       lastEventLabelModel.eventIdList.contains(highestPriorityEvent.eventIdentifier) {
                        eventLabelModels.append(self.createOverflowEventLabel(notDisplayEvents: notDisplayEvents))
                        continue
                    }
                }
                
                // イベントが対象日１日のみの場合
                if calendar.days(from: highestPriorityEvent.startDate, to: highestPriorityEvent.endDate) == 0 {
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
                if calendar.isDate(targetDate, inSameDayAs: highestPriorityEvent.startDate)
                    || weekDays.first == day {
                    // イベントが１週間に収まるようにイベントの日数を調整
                    let eventDaysBetween = calendar.days(from: targetDate, to: highestPriorityEvent.endDate)
                    let minEventDaysBetween = min(weekDays.last! - day, eventDaysBetween)
                    let someDaysEventLabel = self.createSomeDaysEventLabel(eventDaysBetween: minEventDaysBetween,
                                                                           notDisplayEvents: notDisplayEvents,
                                                                           highestPriorityEvent: highestPriorityEvent,
                                                                           targetDate: targetDate,
                                                                           weekEventColumns: weekEventColumns,
                                                                           lastEventLabelModel: eventLabelModels.last)
                    eventLabelModels.append(someDaysEventLabel)
                    continue
                }
            }
            
            weekEventColumns.append(eventLabelModels)
        }
        return weekEventColumns
    }
    
    /// 必要であれば前日以前のイベント分、非表示タイプのEventLabelModelを生成
    /// - parameter lastEventLabelModel: 前日のEventLabelModel
    /// - parameter highestPriorityEvent: 表示させる優先度が最も高いイベント
    /// - returns: 非表示にする日数分の非表示タイプのEventLabelModel
    private func createOverflowLabelsForPastEventsIfNeeded(lastEventLabelModel: EventLabelModel?,
                                                           highestPriorityEventId: String) -> [EventLabelModel] {
        // 前日の３段目のイベントが省略されていなく、そのイベントの期間が対象日も含まれているか確認
        if let lastEventLabelModel = lastEventLabelModel,
           lastEventLabelModel.eventDisplayType == .full,
           lastEventLabelModel.eventIdList.contains(highestPriorityEventId) {
            // 前日のイベントを非表示にする処理を実施
            let element = EventLabelModel(eventDisplayType: .overflow,
                                          eventIdList: [highestPriorityEventId],
                                          length: 1,
                                          title: Constants.PLUS + "1",
                                          color: Color.clear)
            return Array(repeatElement(element, count: lastEventLabelModel.length - 1))
        }
        return []
    }
    
    /// 非表示タイプのEventLabelModelを生成
    /// - parameter notDisplayEvents: 表示されていないイベントのリスト
    /// - returns: 非表示タイプのEventLabelModel
    private func createOverflowEventLabel(notDisplayEvents: [EKEvent]) -> EventLabelModel {
        // 対象日の非表示にするイベントID
        let overEventId: [String] = notDisplayEvents.map { $0.eventIdentifier }
        // タイトル（"＋非表示のイベント数"）
        let title = Constants.PLUS + "\(overEventId.count)"
        return EventLabelModel(eventDisplayType: .overflow,
                               eventIdList: overEventId,
                               length: 1,
                               title: title,
                               color: Color.clear)
    }
    
    /// イベント日数が２日以上のEventLabelModelを生成
    /// - parameter eventDaysBetween: イベントの日数
    /// - parameter notDisplayEvents: 表示されていないイベントのリスト
    /// - parameter highestPriorityEvent: 表示する優先度が最も高いイベント
    /// - parameter targetDate: 対象日
    /// - parameter weekEventColumns: 表示することが決まっているイベント
    /// - parameter lastEventLabelModel: 前日のイベントモデル
    /// - returns: EventLabelModel
    private func createSomeDaysEventLabel(eventDaysBetween: Int,
                                          notDisplayEvents: [EKEvent],
                                          highestPriorityEvent: EKEvent,
                                          targetDate: Date,
                                          weekEventColumns: [[EventLabelModel]],
                                          lastEventLabelModel: EventLabelModel?) -> EventLabelModel {
        // 週初めにイベントが終了日、もしくは週の最終日にイベントが開始日の場合、この後の処理は行わない
        if eventDaysBetween == 0 {
            return EventLabelModel(eventDisplayType: .full,
                                   eventIdList: [highestPriorityEvent.eventIdentifier],
                                   length: 1,
                                   title: highestPriorityEvent.title,
                                   color: Color(cgColor: highestPriorityEvent.calendar.cgColor))
        }
        
        // 表示するイベントの日数分For文を回す
        for dayOffset in 1...eventDaysBetween {
            // 他の日を確認し、表示しようとしているイベントより優先するイベントがある場合は、優先度を調整する
            if let nextDay = Calendar.current.specifiedDay(for: targetDate, at: targetDate.day + dayOffset) {
                // 対象日が含まれるイベントに絞る
                let eventsOfTargetDate = self.filterEvents(for: nextDay)
                // 表示されていないイベント（表示させる優先度の高いイベント）
                if let notNextDisplayEvents = self.filterNotDisplayEvents(excluding: weekEventColumns,
                                                                          from: eventsOfTargetDate).first(where: { event in
                    if lastEventLabelModel?.eventDisplayType == .full,
                       lastEventLabelModel?.eventIdList.first != event.eventIdentifier {
                        return event.startDate.day >= targetDate.day
                    }
                    return true
                }) {
                    // 表示するイベントと次の日のイベントが異なる場合
                    if highestPriorityEvent.eventIdentifier != notNextDisplayEvents.eventIdentifier {
                        // 表示可能なイベントを抽出
                        if let newDisplayEvent = notDisplayEvents.first(where: {
                            let newDaysBetween = Calendar.current.dateComponents([.day], from: $0.startDate, to: $0.endDate).day ?? 0
                            return newDaysBetween < dayOffset
                        }) {
                            let newDaysBetween = Calendar.current.dateComponents([.day], from: newDisplayEvent.startDate, to: newDisplayEvent.endDate).day ?? 0
                            return EventLabelModel(eventDisplayType: .full,
                                                   eventIdList: [newDisplayEvent.eventIdentifier],
                                                   length: newDaysBetween + 1,
                                                   title: newDisplayEvent.title,
                                                   color: Color(cgColor: newDisplayEvent.calendar.cgColor))
                        } else {
                            return EventLabelModel(eventDisplayType: .none,
                                                   eventIdList: [],
                                                   length: 1,
                                                   title: String.empty,
                                                   color: Color.clear)
                        }
                    }
                }
            }
        }
        return EventLabelModel(eventDisplayType: .full,
                               eventIdList: [highestPriorityEvent.eventIdentifier],
                               length: eventDaysBetween + 1,
                               title: highestPriorityEvent.title,
                               color: Color(highestPriorityEvent.calendar.cgColor))
    }
    
    /// 指定の日付を元にイベントをフィルタリングする
    /// - parameter date: 対象日
    /// - returns: フィルタリングされたイベント
    private func filterEvents(for date: Date) -> [EKEvent] {
        let calendar = Calendar.current
        return self.events.filter {
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
    
    /// 表示することが決まっていないイベントにフィルタリングする
    /// - parameter weeklyLabels: 表示することが決まっているイベント
    /// - parameter eventsOfTargetDate: 対象日の全てのイベント
    /// - returns: [EKEvent]
    private func filterNotDisplayEvents(excluding weeklyLabels: [[EventLabelModel]],
                                        from eventsOfTargetDate: [EKEvent]) -> [EKEvent] {
        return eventsOfTargetDate.filter { targetEvent in
            return !weeklyLabels.contains{ displayEventLabelModels in
                displayEventLabelModels.contains { displayEvent in
                    displayEvent.eventIdList.contains { targetEvent.eventIdentifier == $0 }
                }
            }
        }
    }
    
    /// 表示させる優先度が最も高いイベントを取得する
    /// - parameter notDisplayEvents: 表示することが決まっていないイベント
    /// - parameter eventLabelModel: 前日のイベントモデル
    /// - parameter targetDay: イベントを表示する対象日にち
    /// - returns: 優先度が最も高いイベント
    private func getHighestPriorityEvent(notDisplayEvents: [EKEvent],
                                         lastEventLabelModel: EventLabelModel?,
                                         targetDay: Int) -> EKEvent? {
        return notDisplayEvents.first(where: { event in
            if lastEventLabelModel?.eventDisplayType == .full,
               lastEventLabelModel?.eventIdList.first != event.eventIdentifier {
                // 前日にイベントが存在し異なるイベントの場合は、
                // 表示できるものを優先する（イベントの開始日が対象日から始まるものに優先する）
                return event.startDate.day >= targetDay
            }
            return true
        })
    }
    
    /// 新しく追加されたイベントを特定する
    /// - parameter events: イベントリスト
    /// - parameter monthModels: 月モデル
    /// - returns: 追加されたイベント
    private func getAddedEvent(_ events: [EKEvent],
                               for monthModels: [MonthModel]) -> EKEvent? {
        return events.first(where:{ event in
            !monthModels.contains { monthModel in
                monthModel.weekModels.contains { weekModel in
                    weekModel.eventLabelModel.contains { eventLabelModel in
                        eventLabelModel.contains { eventModel in
                            eventModel.eventIdList.contains { $0 == event.eventIdentifier }
                        }
                    }
                }
            }
        })
    }
    
    // MARK: - Publicメソッド
    /// イベントを取得
    /// - parameter referenceMonthForEvents: イベントを取得するための基準となる月
    /// - parameter monthOffset: 基準月からのオフセット（基準値からの数ヶ月前（または後））
    func fetchEvent(referenceMonthForEvents: Date,
                    monthOffset: Int) -> [EKEvent] {
        do {
            // 追加でイベントを取得する範囲
            let monthsAgo = DateComponents(month: monthOffset < 0 ? monthOffset : 0)
            let monthsAdd = DateComponents(month: monthOffset < 0 ? 0 : monthOffset + 1)
            // 取得するイベントの期間
            guard let thisMonth = Calendar.current.specifiedDay(for: referenceMonthForEvents, at: 1),
                  let startDate = Calendar.current.date(byAdding: monthsAgo, to: thisMonth),
                  let endDate = Calendar.current.date(byAdding: monthsAdd, to: thisMonth) else {
                return []
            }
            return try eventRepository.fetchEvent(startDate: startDate, endDate: endDate)
        } catch let eventError {
            Logger().log(eventError.errorDescription ?? String.empty, level: .error)
            self.eventErrorAlertType = .init(error: eventError)
            return []
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
    
    /// 必要であれば追加でイベントを取得
    /// - parameter id: 表示しているイベントのID（日付）
    func loadMoreMonthsIfNeeded(yearMonthString: String) {
        Task {
            // カレンダーイベントへのアクセス権限がない場合はリターン
            if !EventStoreManager.shared.isFullAccessToEvents() {
                return
            }
            if self.monthModels.last?.yearMonthString == yearMonthString {
                // 保持しているイベントの中で１番最新の月と、表示しているイベントが一致する場合
                // 追加で未来１ヶ月分イベントを取得
                if let date = DateUtilities.convertStringToUtcDate(dateString: yearMonthString,
                                                                   format: Constants.YEAR_MONTH_DATE_FORMAT_KEY) {
                    self.events = self.fetchEvent(referenceMonthForEvents: date, monthOffset: 1)
                    if let monthModel = await self.createMonthModel(date: date, monthOffset: 1) {
                        self.monthModels.append(monthModel)
                    }
                }
            }
            if self.monthModels.first?.yearMonthString == yearMonthString {
                // 保持しているイベントの中で１番目に古い月と、表示しているイベントが一致する場合
                // 追加で過去1年分イベントを取得
                if let date = DateUtilities.convertStringToUtcDate(dateString: yearMonthString,
                                                                   format: Constants.YEAR_MONTH_DATE_FORMAT_KEY) {
                    self.events = self.fetchEvent(referenceMonthForEvents: date, monthOffset: -1)
                    if let monthModel = await self.createMonthModel(date: date, monthOffset: -1) {
                        self.monthModels.insert(monthModel, at: 0)
                    }
                }
            }
        }
    }
    
    /// カレンダーの表示されている月が非表示になった時の処理
    func calendarOnDisappear() {
        // 表示月が今月であれば今日ボタンは押下できない
        let thisMonthString = DateUtilities.convertDateToString(date: Date(),
                                                                format: Constants.YEAR_MONTH_DATE_FORMAT_KEY)
        self.isTodayButtonDisabled = self.selectedCalendarID == thisMonthString
    }
    
    /// 今日ボタンを押下時の処理
    func onTapTodayButton() {
        // IDを今日にセット
        let thisMonthString = DateUtilities.convertDateToString(date: Date(),
                                                                format: Constants.YEAR_MONTH_DATE_FORMAT_KEY)
        self.selectedCalendarID = thisMonthString ?? String.empty
    }
}
