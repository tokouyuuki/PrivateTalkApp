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
}

// MARK: - カレンダー View
struct CalendarView: View {
    
    // カレンダーのViewModel
    @StateObject private var calendarViewModel = CalendarViewModel()
    
    // 現在表示中の月のID
    @State private var calendarCellID: Date?
    
    // 有効(true): 今日ボタン押せない ／ 無効(false): 今日ボタン押せる
    @State private var todayButtonEnable: Bool = true
    
    var body: some View {
        VStack(spacing: 0.0) {
            // ヘッダー
            HeaderView(todayButtonEnable: todayButtonEnable,
                       yearMonthString: calendarViewModel.yearMonthString,
                       onTodayButtonTapped: {
                // 今日の日付にカレンダーを更新させる
                calendarCellID = calendarViewModel.getThisMonth()
            },
                       onAddEventButtonTapped: {
                // イベント追加Viewを表示
                calendarViewModel.onTapAddEventView()
            })
            // カレンダーの曜日ヘッダー
            CalendarWeekdayHeaderView()
            // カレンダー
            GeometryReader { geometry in
                ScrollView {
                    LazyVStack {
                        // 月のセルを生成
                        ForEach(calendarViewModel.monthModels, id: \.id) { monthModel in
                            CalendarMonthCell(monthModel: monthModel,
                                              yearMonthString: calendarViewModel.yearMonthString,
                                              deviceWidth: geometry.size.width,
                                              deviceHeight: geometry.size.height,
                                              onAppear: {
                                calendarViewModel.setYearMonthString(monthModel.id)
                                calendarViewModel.loadMoreMonthsIfNeeded(id: monthModel.id)
                                todayButtonEnable = calendarCellID == calendarViewModel.getThisMonth()
                            })
                        }
                        .onAppear {
                            calendarCellID = calendarViewModel.getThisMonth()
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollPosition(id: $calendarCellID)
            }
        }
        .padding(.vertical, 5.0)
        .sheet(isPresented: $calendarViewModel.showEventAddView,
               content: {
            // イベント追加View
            EventAddView(eventAddViewModel: .init(startDate: calendarViewModel.selectedDate,
                                                  endDate: calendarViewModel.selectedEndDate))
        })
        .eventErrorAlert(type: $calendarViewModel.eventErrorAlertType, onDismiss: {})
    }
}

// MARK: - ヘッダー
private struct HeaderView: View {
    
    // 有効(true): 今日ボタン押せない ／ 無効(false): 今日ボタン押せる
    let todayButtonEnable: Bool
    
    // 年月文字列
    let yearMonthString: String
    
    // 今日ボタンをタップ時に呼ばれるクロージャ
    let onTodayButtonTapped: () -> Void
    
    // イベント追加ボタンをタップ時に呼ばれるクロージャ
    let onAddEventButtonTapped: () -> Void
    
    var body: some View {
        VStack(spacing: 0.0) {
            // 今日ボタンと予定追加ボタン
            HStack(spacing: 20.0) {
                TodayButton(todayButtonEnable: todayButtonEnable,
                            onTapped: {
                    onTodayButtonTapped()
                })
                AddEventButton(onTapped: {
                    onAddEventButtonTapped()
                })
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            // 年月テキスト
            Text(yearMonthString)
                .font(.system(size: 30.0, weight: .bold))
                .foregroundStyle(Color.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 10.0)
        .padding(.bottom, 8.0)
    }
}

// MARK: - 今日を表示するボタン
private struct TodayButton: View {
    
    // 有効(true): 今日ボタン押せない ／ 無効(false): 今日ボタン押せる
    let todayButtonEnable: Bool
    
    // ボタンタップ時に呼ばれるクロージャ
    let onTapped: () -> Void
    
    var body: some View {
        Button(action: {
            onTapped()
        }) {
            Text(Constants.TODAY_BUTTON_TEXT_KEY)
                .font(.system(size: 20.0))
                .foregroundStyle(.symbol)
        }
        .disabled(todayButtonEnable)
    }
}

// MARK: - 予定を追加するボタン
private struct AddEventButton: View {
    
    // ボタンタップ時に呼ばれるクロージャ
    let onTapped: () -> Void
    
    var body: some View {
        Button(action: {
            onTapped()
        }) {
            Image(systemName: Constants.ADD_SCHEDULE_BUTTON_IMAGE_NAME)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .foregroundStyle(.symbol)
                .frame(width: 30.0, height: 30.0)
        }
    }
}

// MARK: - 日曜から土曜までの曜日が表示されたヘッダー
private struct CalendarWeekdayHeaderView: View {
    
    // 曜日
    let weeks = Calendar.current.shortWeekdaySymbols
    
    var body: some View {
        HStack(spacing: 0.0) {
            ForEach(weeks, id: \.self) { week in
                Text(LocalizedStringKey(week))
                    .frame(maxWidth: .infinity)
                    .font(.system(size: 11.0))
                    .padding(.vertical, 2.0)
                    .background(.symbol)
            }
        }
    }
}

// MARK: - １月分のカレンダーセル
private struct CalendarMonthCell: View {
    
    // 表示するイベント
    let monthModel: MonthModel
    
    // 年月文字列
    let yearMonthString: String
    
    // デバイス幅
    let deviceWidth: CGFloat
    
    // デバイス縦幅
    let deviceHeight: CGFloat
    
    // Viewが非表示になる時に呼ばれるクロージャ
    let onAppear: () -> Void
    
    var body: some View {
        // 存在する週の数だけセルを生成する
        LazyVGrid(columns: [GridItem(.adaptive(minimum: deviceWidth))], spacing: 0.0) {
            ForEach(monthModel.weekModels) { weekModel in
                Divider()
                // 週単位のセル
                WeekCell(weekModel: weekModel,
                         deviceWidth: deviceWidth,
                         weekCellHeight: deviceHeight / 5.0)
            }
        }
        .onAppear() {
            onAppear()
        }
    }
}

// MARK: - １週間分のセル
private struct WeekCell: View {
    
    // 表示するイベント
    let weekModel: WeekModel
    
    // デバイス幅
    let deviceWidth: CGFloat
    
    // セルの縦幅
    let weekCellHeight: CGFloat
    
    var body: some View {
        VStack(alignment: .leading, spacing: 13.0) {
            // １週間の日数分（７日）セルを生成する
            HStack(spacing: 0.0) {
                ForEach(Array(weekModel.displayDates.enumerated()), id: \.offset) { _, day in
                    // 日単位のセル
                    Text(day)
                        .fontWeight(.semibold)
                        .padding(.top, 13.0)
                        .frame(width: deviceWidth / 7,
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
                            EventLabel(event: event,
                                       deviceWidth: deviceWidth)
                        }
                    }
                }
            }
        }
        .frame(height: weekCellHeight, alignment: .top)
    }
}

// MARK: - イベントラベル
private struct EventLabel: View {
    
    // 表示するイベント
    let event: EventLabelModel
    
    // デバイス幅
    let deviceWidth: CGFloat
    
    // ライト/ダークモードの状態を取得
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    
    var body: some View {
        switch event.eventDisplayType {
        case .full:
            // イベントが表示されたボタン
            Button {
                // ボタンアクション
            } label: {
                Text(event.title)
                    .font(.system(size: 10.0, weight: .bold))
                    .padding(EdgeInsets(top: 0.0, leading: 2.0, bottom: 0.0, trailing: 0.0))
                    .frame(maxHeight: .infinity)
                    .frame(width: (deviceWidth / 7) * CGFloat(event.length) - 4, alignment: .leading)
                    .foregroundStyle(adjustedEventColor(for: colorScheme,
                                                        color: event.color))
                    .background(event.color.opacity(0.3))
                    .cornerRadius(4.0)
            }
            .frame(width: (deviceWidth / 7) * CGFloat(event.length), height: 15.0, alignment: .center)
        case .overflow:
            // 予定数が表示されたテキスト
            Text(event.title)
                .font(.system(size: 10.0, weight: .light))
                .frame(width: (deviceWidth / 7) * CGFloat(event.length))
        case .none:
            // 空白
            Spacer()
                .frame(width: (deviceWidth / 7) * CGFloat(event.length))
        }
    }
    
    /// ライト/ダークモード対応したイベントの色を取得
    /// - parameter colorScheme: 現在の状態（ライトかダークか）
    /// - parameter color: イベントの色
    /// - returns: ライト/ダークモードに対応したイベントの色
    private func adjustedEventColor(for colorScheme: ColorScheme, color: Color) -> Color {
        switch colorScheme {
        case .light:
            return Color(UIColor(color).adjustedBrightness(by: 0.5))
        case .dark:
            return Color(UIColor(color).adjustedBrightness(by: 1.7))
        @unknown default:
            return Color(UIColor(color))
        }
    }
}

#Preview {
    CalendarView()
}
