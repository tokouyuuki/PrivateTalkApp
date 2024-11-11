//
//  HomeView.swift
//  PrivateTalkApp
//
//  Created by 都甲裕希 on 2024/08/10.
//

import SwiftUI

// MARK: - Constants
private struct Constants {
    static let ADD_SCHEDULE_BUTTON_IMAGE_NAME = "plus.circle.fill"
    static let TODAY_BUTTON_TEXT_KEY = LocalizedStringKey("today_button_text")
}

// MARK: - ホーム View
struct HomeView: View {
    
    // カレンダーのViewModel
    @StateObject private var calendarViewModel = CalendarViewModel()
    // 有効(true): 今日ボタン押せない ／ 無効(false): 今日ボタン押せる
    @State private var todayButtonEnable: Bool = true
    
    var body: some View {
        VStack(spacing: 8.0) {
            // ヘッダー
            headerView
            // カレンダー
            CalendarView(calendarViewModel: calendarViewModel)
        }
        .padding(.vertical, 5.0)
        .sheet(isPresented: $calendarViewModel.showEventAddView,
               onDismiss: {
            // 新しくイベントを取得し、カレンダーを更新する
            calendarViewModel.fetchEvent()
        },
               content: {
            EventAddView(eventAddViewModel: .init(startDate: calendarViewModel.selectedDate,
                                                  endDate: calendarViewModel.selectedEndDate))
        })
        .eventErrorAlert(type: $calendarViewModel.eventErrorAlertType, onDismiss: {})
    }
    
    // ヘッダー部分
    private var headerView: some View {
        VStack(spacing: 0.0) {
            // 今日ボタンと予定追加ボタン
            HStack(spacing: 20.0) {
                TodayButton(todayButtonEnable: todayButtonEnable,
                            onButtonTapped: {
                    // 今日の日付をセットし、カレンダーを更新させる
                    calendarViewModel.tapTodayButton()
                })
                AddEventButton(onTapped: {
                    calendarViewModel.onTapAddEventView()
                })
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            // 年月テキスト
            Text(calendarViewModel.yearMonthString)
                .font(.system(size: 30.0, weight: .bold))
                .foregroundStyle(Color.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 10.0)
    }
}

// MARK: - 今日を表示するボタン
private struct TodayButton: View {
    
    let todayButtonEnable: Bool
    let onButtonTapped: () -> Void
    
    var body: some View {
        Button(action: {
            onButtonTapped()
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

#Preview {
    HomeView()
}
