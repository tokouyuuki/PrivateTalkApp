//
//  CalendarView.swift
//  PrivateTalkApp
//
//  Created by 都甲裕希 on 2024/08/16.
//

import SwiftUI
import FSCalendar

// MARK: - クロージャの更新先を決めるenum
enum EventAction {
    // 表示する年月の更新
    case updateDisplayDate(Date)
    // 選択日の更新
    case updateSelectedDate(Date)
}

// MARK: - FSCalendarView
struct CalendarView: UIViewRepresentable {
    
    typealias UIViewType = FSCalendar
    
    private struct Constants {
        static let DEFAULT_LANGUAGE = "ja-JP"
        static let HEADER_HEIGHT = 0.0
        static let PREVIOUS_AND_NEXT_MONTH_ALPHA = 0.0
        static let WEEKDAY_FONT_SIZE = 20.0
        static let TITLE_FONT_SIZE = 16.0
        static let TODAY_AND_SELECTED_BORDER_RADIUS = 1.0
    }
    
    // カレンダーのViewModel
    let calendarViewModel: CalendarViewModel
    
    // 今日ボタンの有効／無効を制御
    @Binding var todayButtonEnable: Bool
    
    // 親Viewにカレンダーの現在日付を渡すためのクロージャ
    let onCurrentDateChanged: (EventAction) -> Void
    
    func makeCoordinator() -> FSCalendarCoordinator {
        return FSCalendarCoordinator(parent: self)
    }
    
    func makeUIView(context: Context) -> FSCalendar {
        // 設定されている優先言語を取得
        let preferredLanguage = Locale.preferredLanguages.first ?? Constants.DEFAULT_LANGUAGE
        // カレンダーの設定
        let fsCalendar = FSCalendar()
            .setLocale(identifier: preferredLanguage)
            .setHeaderHeight(height: Constants.HEADER_HEIGHT)
            .setHeaderMinimumDissolvedAlpha(alpha: Constants.PREVIOUS_AND_NEXT_MONTH_ALPHA)
            .setWeekdayFont(size: Constants.WEEKDAY_FONT_SIZE)
            .setCalendarWeekdayBackgroundColor(color: .symbol)
            .setWeekdayTextColor(color: .label)
            .setTitleFont(size: Constants.TITLE_FONT_SIZE, weight: .bold)
            .setTodayColor(color: .symbol)
            .setSelectionColor(color: .clear)
            .setBorderSelectionColor(color: .symbol)
            .setTitleSelectionColor(color: .label)
            .setTitleDefaultColor(color: .label)
            .setTitleWeekendColor(color: .symbol)
            .setBorderRadius(radius: Constants.TODAY_AND_SELECTED_BORDER_RADIUS)
        
        fsCalendar.delegate = context.coordinator
        fsCalendar.dataSource = context.coordinator
        
        // 月初と今日の日付を親Viewに渡す
        self.onCurrentDateChanged(.updateDisplayDate(fsCalendar.currentPage))
        self.onCurrentDateChanged(.updateSelectedDate(fsCalendar.today ?? Date()))
        
        return fsCalendar
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        // カレンダーで表示している月とCalendarModelの月が異なるかどうか
        if !self.calendarViewModel.isMatchedDate(dateToCompare: uiView.currentPage) {
            if let displayDate = self.calendarViewModel.calendarModel?.displayDate {
                // カレンダーの表示を今月にし、選択日を今日にする
                uiView.select(displayDate, scrollToDate: true)
                self.onCurrentDateChanged(.updateSelectedDate(displayDate))
                self.todayButtonEnable = true
            }
        }
    }
}

// MARK: - Coordinator
final class FSCalendarCoordinator: NSObject, FSCalendarDelegate, FSCalendarDataSource {
    
    private var parent: CalendarView
    
    init(parent: CalendarView) {
        self.parent = parent
    }
    
    /// 年月を変更した際の処理
    /// - parameter calendar: FSCalendar
    func calendarCurrentPageDidChange(_ calendar: FSCalendar) {
        // 月初の日付を親Viewに渡す
        self.parent.onCurrentDateChanged(.updateDisplayDate(calendar.currentPage))
        Task { @MainActor in
            if let today = calendar.today {
                if self.parent.calendarViewModel.isMatchedDate(dateToCompare: today) {
                    // カレンダーが今日の月だったら、今日ボタンを押せなくする
                    self.parent.todayButtonEnable = true
                } else {
                    // カレンダーが今日の月でなければ、今日ボタンを押せるようにする
                    self.parent.todayButtonEnable = false
                }
            }
        }
    }
    
    // 日付を選択した際の処理
    func calendar(_ calendar: FSCalendar, didSelect date: Date, at monthPosition: FSCalendarMonthPosition) {
        // 選択された日付を親Viewに渡す
        self.parent.onCurrentDateChanged(.updateSelectedDate(date))
    }
}

// MARK: - extension
extension FSCalendar {
    
    /// 言語設定
    /// - parameter identifier: ロケールの識別子（日本語表示の場合は"ja-JP"）
    @discardableResult
    func setLocale(identifier: String) -> Self {
        self.locale = Locale(identifier: identifier)
        return self
    }
    
    /// ヘッダーの高さをセット
    /// - parameter height: ヘッダーの高さ（0.0で非表示）
    @discardableResult
    func setHeaderHeight(height: CGFloat) -> Self {
        self.headerHeight = height
        return self
    }
    
    /// 前月、翌月表示のアルファ量をセット
    /// - parameter alpha: アルファ量（0で非表示）
    @discardableResult
    func setHeaderMinimumDissolvedAlpha(alpha: CGFloat) -> Self {
        self.appearance.headerMinimumDissolvedAlpha = alpha
        return self
    }
    
    /// 曜日表示のテキストサイズをセット
    /// - parameter size: テキストサイズ
    @discardableResult
    func setWeekdayFont(size: CGFloat) -> Self {
        self.appearance.weekdayFont = UIFont.systemFont(ofSize: size)
        return self
    }
    
    /// 曜日表示の背景色をセット
    /// - parameter color: 背景色
    @discardableResult
    func setCalendarWeekdayBackgroundColor(color: UIColor) -> Self {
        self.calendarWeekdayView.backgroundColor = color
        return self
    }
    
    /// 曜日表示のテキストカラーをセット
    /// - parameter color: テキストカラー
    @discardableResult
    func setWeekdayTextColor(color: UIColor) -> Self {
        self.appearance.weekdayTextColor = color
        return self
    }
    
    /// 日付のテキスト、ウェイトサイズをセット
    /// - parameter size: テキストサイズ
    /// - parameter weight: ウェイトサイズ
    @discardableResult
    func setTitleFont(size: CGFloat, weight: UIFont.Weight) -> Self {
        self.appearance.titleFont = UIFont.systemFont(ofSize: size, weight: weight)
        return self
    }
    
    /// 本日の背景色をセット
    /// - parameter color: 背景色
    @discardableResult
    func setTodayColor(color: UIColor) -> Self {
        self.appearance.todayColor = color
        return self
    }
    
    /// 選択した日付の背景色をセット
    /// - parameter color: 背景色
    @discardableResult
    func setSelectionColor(color: UIColor) -> Self {
        self.appearance.selectionColor = color
        return self
    }
    
    /// 選択した日付のボーダーカラーをセット
    /// - parameter color: ボーダーカラー
    @discardableResult
    func setBorderSelectionColor(color: UIColor) -> Self {
        self.appearance.borderSelectionColor = color
        return self
    }
    
    /// 選択した日付のテキストカラーをセット
    /// - parameter color: テキストカラー
    @discardableResult
    func setTitleSelectionColor(color: UIColor) -> Self {
        self.appearance.titleSelectionColor = color
        return self
    }
    
    /// 平日の日付のテキストカラーをセット
    /// - parameter color: テキストカラー
    @discardableResult
    func setTitleDefaultColor(color: UIColor) -> Self {
        self.appearance.titleDefaultColor = color
        return self
    }
    
    /// 週末（土、日曜の）日付のテキストカラーをセット
    /// - parameter color: テキストカラー
    @discardableResult
    func setTitleWeekendColor(color: UIColor) -> Self {
        self.appearance.titleWeekendColor = color
        return self
    }
    
    /// 本日・選択日の塗りつぶし角丸量
    /// - parameter radius: 角丸量
    @discardableResult
    func setBorderRadius(radius: CGFloat) -> Self {
        self.appearance.borderRadius = radius
        return self
    }
}

//#Preview {
//    CalendarView()
//}
