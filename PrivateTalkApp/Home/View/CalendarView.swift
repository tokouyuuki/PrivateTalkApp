//
//  CalendarView.swift
//  PrivateTalkApp
//
//  Created by 都甲裕希 on 2024/08/16.
//

import SwiftUI
import FSCalendar

// MARK: - FSCalendarView
struct CalendarView: UIViewRepresentable {
    
    private struct Constants {
        static let DEFAULT_LANGUAGE = "ja-JP"
        static let HEADER_DATE_FORMAT_KEY = "calendar_format"
        static let HEADER_TITLE_FONT_SIZE = 20.0
        static let PREVIOUS_AND_NEXT_MONTH_ALPHA = 0.0
        static let WEEKDAY_FONT_SIZE = 20.0
        static let TITLE_FONT_SIZE = 16.0
        static let TODAY_AND_SELECTED_BORDER_RADIUS = 1.0
    }
    
    func makeCoordinator() -> FSCalendarCoordinator {
        return FSCalendarCoordinator(parent: self)
    }
    
    func makeUIView(context: Context) -> some UIView {
        // 設定されている優先言語を取得
        let preferredLanguage = Locale.preferredLanguages.first ?? Constants.DEFAULT_LANGUAGE
        // 設定されている言語に合わせてフォーマットを取得
        let format = NSLocalizedString(Constants.HEADER_DATE_FORMAT_KEY, comment: String.empty)
        // カレンダーの設定
        let fsCalendar = FSCalendar()
            .setLocale(identifier: preferredLanguage)
            .setHeaderDateFormat(format: format)
            .setHeaderTitleFont(size: Constants.HEADER_TITLE_FONT_SIZE)
            .setHeaderTitleColor(color: .label)
            .setHeaderMinimumDissolvedAlpha(alpha: Constants.PREVIOUS_AND_NEXT_MONTH_ALPHA)
            .setWeekdayFont(size: Constants.WEEKDAY_FONT_SIZE)
            .setCalendarWeekdayBackgroundColor(color: .calendarPrimary)
            .setWeekdayTextColor(color: .iconBlack)
            .setTitleFont(size: Constants.TITLE_FONT_SIZE, weight: .bold)
            .setTodayColor(color: .calendarPrimary)
            .setSelectionColor(color: .clear)
            .setBorderSelectionColor(color: .calendarSelectedBackground)
            .setTitleSelectionColor(color: .iconBlack)
            .setTitleDefaultColor(color: .iconBlack)
            .setTitleWeekendColor(color: .calendarPrimary)
            .setBorderRadius(radius: Constants.TODAY_AND_SELECTED_BORDER_RADIUS)
        
        fsCalendar.delegate = context.coordinator
        fsCalendar.dataSource = context.coordinator
        
        return fsCalendar
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        
    }
}

// MARK: - Coordinator
class FSCalendarCoordinator: NSObject, FSCalendarDelegate, FSCalendarDataSource {
    
    var parent: CalendarView
    
    init(parent: CalendarView) {
        self.parent = parent
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
    
    /// ヘッダー表示のフォーマットをセット
    /// - parameter format: フォーマット
    @discardableResult
    func setHeaderDateFormat(format: String) -> Self {
        self.appearance.headerDateFormat = format
        return self
    }
    
    /// ヘッダーテキストサイズをセット
    /// - parameter size: テキストサイズ
    @discardableResult
    func setHeaderTitleFont(size: CGFloat) -> Self {
        self.appearance.headerTitleFont = UIFont.systemFont(ofSize: size)
        return self
    }
    
    /// ヘッダーテキストカラーをセット
    /// - parameter color: テキストカラー
    @discardableResult
    func setHeaderTitleColor(color: UIColor) -> Self {
        self.appearance.headerTitleColor = color
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

#Preview {
    CalendarView()
}
