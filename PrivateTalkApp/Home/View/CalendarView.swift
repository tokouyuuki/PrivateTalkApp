//
//  CalendarView.swift
//  PrivateTalkApp
//
//  Created by 都甲裕希 on 2024/08/16.
//

import SwiftUI

// MARK: - Constants
private struct Constants {
    static let DEFAULT_LANGUAGE = "ja-JP"
    static let ADD_SCHEDULE_BUTTON_IMAGE_NAME = "plus.circle.fill"
    static let TODAY_BUTTON_TEXT_KEY = LocalizedStringKey("today_button_text")
    static let SUNDAY_TEXT_KEY = "sunday_text"
    static let MONDAY_TEXT_KEY = "monday_text"
    static let TUESDAY_TEXT_KEY = "tuesday_text"
    static let WEDNESDAY_TEXT_KEY = "wednesday_text"
    static let THURSDAY_TEXT_KEY = "thursday_text"
    static let FRIDAY_TEXT_KEY = "friday_text"
    static let SATURDAY_TEXT_KEY = "saturday_text"
}

// MARK: - カレンダー View
struct CalendarView: View {
    
    // カレンダーのViewModel
    @ObservedObject var calendarViewModel: CalendarViewModel
    
    // ライト/ダークモードの状態を取得
    @Environment(\.colorScheme) var colorScheme
    
    // 有効(true): 今日ボタン押せない ／ 無効(false): 今日ボタン押せる
    @State private var todayButtonEnable: Bool = true
    
    var body: some View {
        VStack(spacing: 0.0) {
            headerWeek
            calendar
        }
    }
    
    // 日曜から土曜までのヘッダー
    private var headerWeek: some View {
        let weeks = [Constants.SUNDAY_TEXT_KEY,
                     Constants.MONDAY_TEXT_KEY,
                     Constants.TUESDAY_TEXT_KEY,
                     Constants.WEDNESDAY_TEXT_KEY,
                     Constants.THURSDAY_TEXT_KEY,
                     Constants.FRIDAY_TEXT_KEY,
                     Constants.SATURDAY_TEXT_KEY]
        return HStack(spacing: 0.0) {
            ForEach(weeks, id: \.self) { week in
                Text(LocalizedStringKey(week))
                    .frame(maxWidth: .infinity)
                    .font(.system(size: 11.0))
                    .padding(.vertical, 2.0)
                    .background(.symbol)
            }
        }
    }
    
    // カレンダー
    private var calendar: some View {
        GeometryReader { geometry in
            let deviceWidth = geometry.size.width
            // 存在する週の数だけセルを生成する
            LazyVGrid(columns: [GridItem(.adaptive(minimum: deviceWidth))], spacing: 0.0) {
                ForEach(calendarViewModel.weekModelList) { weekModel in
                    Divider()
                    // 週単位のセル
                    ZStack(alignment: .leading) {
                        // １週間の日数分（７日）セルを生成する
                        LazyHGrid(rows: [GridItem(.flexible(maximum: .infinity))], spacing: 0.0) {
                            ForEach(weekModel.displayDateList, id: \.self) { day in
                                // 日単位のセル
                                Text(day)
                                    .fontWeight(.semibold)
                                    .padding(.top, 13.0)
                                    .frame(width: deviceWidth / 7,
                                           height: geometry.size.height / CGFloat(calendarViewModel.weekModelList.count),
                                           alignment: .top)
                            }
                        }
                        // イベント表示セルを生成する
                        VStack(alignment: .leading, spacing: 3.0) {
                            // イベントは１週間分✖︎３段で表示
                            ForEach(0..<weekModel.eventLabelModels.count, id: \.self) { labelIndex in
                                // １週間分のイベント
                                HStack(spacing: 0.0) {
                                    ForEach(weekModel.eventLabelModels[labelIndex]) { (event: EventLabelModel) in
                                        eventLabel(event: event, deviceWidth: deviceWidth)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    /// イベントラベル
    /// - parameter event: 表示するイベントモデル
    /// - parameter deviceWidth: デバイス幅
    /// - returns: イベントならイベントが表示されたボタン、省略なら予定数が表示されたテキスト、イベント無しなら空白
    @ViewBuilder
    private func eventLabel(event: EventLabelModel, deviceWidth: CGFloat) -> some View {
        switch event.eventDisplayType {
        case .full:
            Button {
                // ボタンアクション
            } label: {
                Text(event.title)
                    .font(.system(size: 10.0, weight: .bold))
                    .padding(EdgeInsets(top: 0.0, leading: 2.0, bottom: 0.0, trailing: 0.0))
                    .frame(maxHeight: .infinity)
                    .frame(width: (deviceWidth / 7) * CGFloat(event.length) - 4, alignment: .leading)
                    .foregroundStyle(calendarViewModel.adjustedEventColor(for: colorScheme,
                                                                          color: event.color))
                    .background(event.color.opacity(0.3))
                    .cornerRadius(4.0)
            }
            .frame(width: (deviceWidth / 7) * CGFloat(event.length), height: 15.0, alignment: .center)
        case .overflow:
            Text(event.title)
                .font(.system(size: 10.0, weight: .light))
                .frame(width: (deviceWidth / 7) * CGFloat(event.length))
        case .none:
            Spacer()
                .frame(width: (deviceWidth / 7) * CGFloat(event.length))
        }
    }
}

#Preview {
    CalendarView(calendarViewModel: CalendarViewModel())
}
