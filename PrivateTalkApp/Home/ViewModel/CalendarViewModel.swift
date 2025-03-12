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
    private var eventList = [EKEvent]()
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
            await self.requestFullAccessToEvents()
            // イベント変更通知の設定
            registerObserver()
            // MonthModelsを生成
            await self.createMonthModel(date: Date(), monthOffset: 0)
        }
    }
    
    /// カレンダーイベントへのフルアクセスを要求
    private func requestFullAccessToEvents() async {
        do {
            let isFullAccess = try await EventStoreManager.shared.eventStore.requestFullAccessToEvents()
            if isFullAccess {
                fetchEvent(referenceMonthForEvents: Date(),
                           monthOffset: 0)
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
                self.fetchEvent(referenceMonthForEvents: Date(),
                                monthOffset: 0)
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
    private func createMonthModel(date: Date, monthOffset: Int) async {
        // 生成するモデルの月
        guard let targetMonth = Calendar.current.date(byAdding: DateComponents(month: monthOffset), to: date) else {
            return
        }
        let yearMonthString = DateUtilities.convertDateToString(date: targetMonth,
                                                                format: Constants.YEAR_MONTH_DATE_FORMAT_KEY) ?? String.empty
        // 今月のデータを生成している場合は、カレンダーのIDをセット（初回のみこの処理は実行される）
        if monthOffset == 0 {
            self.selectedCalendarID = yearMonthString
        }
        let weekModels = self.createWeekModels(date: targetMonth)
        // 過去の月を生成した場合は、配列の先頭に挿入
        if monthOffset >= 0 {
            self.monthModels.append(MonthModel(yearMonthString: yearMonthString,
                                               weekModels: weekModels))
        } else {
            self.monthModels.insert(MonthModel(yearMonthString: yearMonthString,
                                               weekModels: weekModels),
                                    at: 0)
        }
    }
    
    /// １ヶ月分の週モデルを生成
    /// - parameter date: 対象の月
    private func createWeekModels(date: Date) -> [WeekModel] {
        let calendar = Calendar.current
        // 開始日、月の日数、月の開始日の曜日を取得
        guard let startMonth = calendar.specifiedDay(for: date, at: 1),
              let numberOfDaysInMonth = calendar.daysInMonth(for: date),
              let firstWeekOfMonth = calendar.dayOfWeek(for: startMonth) else {
            return []
        }
        
        var dateStrings: [String] = []
        // １ヶ月分の日数
        return (1...numberOfDaysInMonth).compactMap { dayOffset in
            // 月の開始日が日曜日から始まらない場合
            if firstWeekOfMonth != 1 && dayOffset == 1 {
                // １週目の日付が存在しない曜日には空文字を追加
                let emptyStrings = Array(repeating: String.empty,
                                         count: firstWeekOfMonth - 1)
                dateStrings.append(contentsOf: emptyStrings)
            }
            
            dateStrings.append(String(dayOffset))
            // １週間ごとにリターン
            if dateStrings.count % 7 == 0 {
                let eventLabelModel = createEventLabelModel(startMonth: startMonth,
                                                            weekOfMonth: dateStrings.count / 7,
                                                            numberOfDaysInMonth: numberOfDaysInMonth)
                return WeekModel(displaydays: dateStrings.suffix(7), eventLabelModel: eventLabelModel)
            }
            // 最終週が日曜日で終わらない時は、日数を計算してリターン
            if dayOffset == numberOfDaysInMonth {
                let daysInFinalWeek = Int(dateStrings.count % 7)
                let weekOfMonth = (dateStrings.count + 7 - daysInFinalWeek) / 7
                let eventLabelModel = createEventLabelModel(startMonth: startMonth,
                                                            weekOfMonth: weekOfMonth,
                                                            numberOfDaysInMonth: numberOfDaysInMonth)
                return WeekModel(displaydays: dateStrings.suffix(daysInFinalWeek), eventLabelModel: eventLabelModel)
            }
            return nil
        }
    }
    
    /// １週間分のイベントを取得
    /// - parameter startMonth: 月の開始日
    /// - parameter weekOfMonth: 月の第何週目
    /// - parameter numberOfDaysInMonth: 月の日数
    /// - returns: [[EventLabelModel]]
    private func createEventLabelModel(startMonth: Date, weekOfMonth: Int, numberOfDaysInMonth: Int) -> [[EventLabelModel]] {
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
    /// イベントを取得
    /// - parameter referenceMonthForEvents: イベントを取得するための基準となる月
    /// - parameter monthOffset: 基準月からのオフセット（基準値からの数ヶ月前（または後））
    func fetchEvent(referenceMonthForEvents: Date,
                    monthOffset: Int) {
        do {
            // 追加でイベントを取得する範囲
            let monthsAgo = DateComponents(month:  monthOffset)
            let monthsAdd = DateComponents(month: monthOffset < 0 ? 0 : monthOffset + 1)
            // 取得するイベントの期間
            guard let thisMonth = Calendar.current.specifiedDay(for: referenceMonthForEvents, at: 1),
                  let startDate = Calendar.current.date(byAdding: monthsAgo, to: thisMonth),
                  let endDate = Calendar.current.date(byAdding: monthsAdd, to: thisMonth) else {
                return
            }
            self.eventList = try eventRepository.fetchEvent(startDate: startDate, endDate: endDate)
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
    
    /// 必要であれば追加でイベントを取得
    /// - parameter id: 表示しているイベントのID（日付）
    func loadMoreMonthsIfNeeded(yearMonthString: String) {
        Task {
            if self.monthModels.last?.yearMonthString == yearMonthString {
                // 保持しているイベントの中で１番最新の月と、表示しているイベントが一致する場合
                // 追加で未来１ヶ月分イベントを取得
                if let date = DateUtilities.convertStringToUtcDate(dateString: yearMonthString,
                                                                   format: Constants.YEAR_MONTH_DATE_FORMAT_KEY) {
                    self.fetchEvent(referenceMonthForEvents: date, monthOffset: 1)
                    await self.createMonthModel(date: date, monthOffset: 1)
                }
            }
            if self.monthModels.first?.yearMonthString == yearMonthString {
                // 保持しているイベントの中で１番目に古い月と、表示しているイベントが一致する場合
                // 追加で過去1年分イベントを取得
                if let date = DateUtilities.convertStringToUtcDate(dateString: yearMonthString,
                                                                   format: Constants.YEAR_MONTH_DATE_FORMAT_KEY) {
                    self.fetchEvent(referenceMonthForEvents: date, monthOffset: -1)
                    await self.createMonthModel(date: date, monthOffset: -1)
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
