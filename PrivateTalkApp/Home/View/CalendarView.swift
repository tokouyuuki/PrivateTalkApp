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
            // 存在する週の数だけセルを生成する
            LazyVGrid(columns: [GridItem(.adaptive(minimum: geometry.size.width))], spacing: 0.0) {
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
                                    .padding(.top, 13)
                                    .frame(width: geometry.size.width / 7,
                                           height: geometry.size.height / CGFloat(calendarViewModel.weekModelList.count),
                                           alignment: .top)
                            }
                        }
                        // イベント表示
                        VStack(alignment: .leading, spacing: 3.0) {
                            // TODO: 後ほど
                            HStack(spacing: 0.0) {
                                Button {
                                    
                                } label: {
                                    Text("予定1")
                                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                                            .font(.system(size: 11.0, weight: .bold))
                                            .background(.green)
                                            .padding(.horizontal, 2)
                                }
                                .frame(width: geometry.size.width / 7 * 1, height: 15.0, alignment: .leading)
                                Button {
                                    
                                } label: {
                                    Text("予定1")
                                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                                            .font(.system(size: 11.0, weight: .bold))
                                            .background(.green)
                                            .padding(.horizontal, 2)
                                }
                                .frame(width: geometry.size.width / 7 * 1, height: 15.0, alignment: .leading)
                                Spacer()
                                    .frame(width: geometry.size.width / 7)
                                    Button {
                                        
                                    } label: {
                                        Text("予定8")
                                            .frame(width: geometry.size.width / 7 * 3 - 4, alignment: .leading)
                                            .font(.system(size: 10.0, weight: .bold))
                                            .background(.green)
                                            .padding(.horizontal, 2)
                                    }
                                .frame(width: geometry.size.width / 7 * 3, height: 14.0, alignment: .leading)
                            }
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    CalendarView(calendarViewModel: CalendarViewModel())
}
