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
    static let HEADER_AND_CALENDAR_SPACING = 8.0
    static let ELEMENTS_IN_THE_HEADER_SPACING = 0.0
    static let HEADER_TITLE_FONT_SIZE = 20.0
    static let TODAY_BUTTON_AND_ADD_SCHEDULE_BUTTON_SPACING = 20.0
    static let ADD_SCHEDULE_BUTTON_WIDTH = 30.0
    static let ADD_SCHEDULE_BUTTON_HEIGHT = 30.0
    static let HEADER_HORIZONTAL = 10.0
    static let MAIN_STACK_PADDING = 5.0
}

// MARK: - ホーム View
struct HomeView: View {
    
    // カレンダーのViewModel
    @StateObject private var calendarViewModel = CalendarViewModel()
    // 有効(true): 今日ボタン押せない ／ 無効(false): 今日ボタン押せる
    @State private var todayButtonEnable: Bool = true
    
    var body: some View {
        VStack(spacing: Constants.HEADER_AND_CALENDAR_SPACING) {
            // ヘッダー
            headerView
            // カレンダー
            CalendarView(calendarViewModel: calendarViewModel,
                         todayButtonEnable: $todayButtonEnable) { eventAction in
                calendarViewModel.handleAction(eventAction)
            }
        }
        .padding(.vertical, Constants.MAIN_STACK_PADDING)
    }
    
    // ヘッダー部分
    private var headerView: some View {
        HStack(spacing: Constants.ELEMENTS_IN_THE_HEADER_SPACING) {
            // 年月テキスト
            Text(calendarViewModel.calendarModel?.displayYearMonthString ?? String.empty)
                .font(.system(size: Constants.HEADER_TITLE_FONT_SIZE, weight: .bold))
                .foregroundStyle(Color.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
            // 今日ボタンと予定追加ボタン
            HStack(spacing: Constants.TODAY_BUTTON_AND_ADD_SCHEDULE_BUTTON_SPACING) {
                TodayButton(todayButtonEnable: todayButtonEnable,
                            onButtonTapped: {
                    // 今日の日付をセットし、カレンダーを更新させる
                    calendarViewModel.tapTodayButton()
                })
                AddEventButton(selectedDate: self.calendarViewModel.selectedDate,
                               selectedEndDate: self.calendarViewModel.selectedEndDate)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, Constants.HEADER_HORIZONTAL)
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
                .font(.system(size: Constants.HEADER_TITLE_FONT_SIZE))
                .foregroundStyle(Color.primary)
        }
        .disabled(todayButtonEnable)
    }
}

// MARK: - 予定を追加するボタン
private struct AddEventButton: View {
    
    // 選択している日付
    let selectedDate: Date
    // 選択している日付の終了日
    var selectedEndDate: Date
    // モーダルシート画面の表示を管理する変数
    @State var isShowSheet = false
    // カレンダーアクセス訴求のアラートを管理する変数
    @State var isShowAlert = false
    
    var body: some View {
        Button(action: {
            if EventStoreManager.shared.isFullAccessToEvents() {
                // カレンダーイベントへのアクセス権がある場合、モーダルシートを表示
                isShowSheet.toggle()
            } else {
                // カレンダーイベントへのアクセス権限がない場合、アラートを表示
                isShowAlert.toggle()
            }
        }) {
            Image(systemName: Constants.ADD_SCHEDULE_BUTTON_IMAGE_NAME)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .foregroundStyle(Color.primary)
                .frame(width: Constants.ADD_SCHEDULE_BUTTON_WIDTH,
                       height: Constants.ADD_SCHEDULE_BUTTON_HEIGHT)
        }
        .sheet(isPresented: $isShowSheet) {
            EventAddView(eventAddViewModel: EventAddViewModel(startDate: selectedDate,
                                                              endDate: selectedEndDate))
        }
        // カレンダーへのフルアクセスを訴求するアラート
        .customAlertDialog(isShowAlert: $isShowAlert,
                           privateTalkAppError: .eventError(.notAccess)) {
            isShowAlert = false
        }
    }
}

#Preview {
    HomeView()
}
