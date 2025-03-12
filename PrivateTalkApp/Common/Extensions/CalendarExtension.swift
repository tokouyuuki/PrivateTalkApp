//
//  Calendar.swift
//  PrivateTalkApp
//
//  Created by 都甲裕希 on 2024/11/07.
//

import Foundation

extension Calendar {
    
    /// 指定した日付にしたものを取得する
    /// - parameter date: 対象日
    /// - parameter day: 変換したい日
    /// - returns: 指定した日付
    func specifiedDay(for date: Date, at day: Int) -> Date? {
        var components = dateComponents([.year, .month], from: date)
        components.day = day
        return self.date(from: components)
    }
    
    /// 月の日数を取得する
    /// - parameter date: 対象日
    /// - returns: 日数
    func daysInMonth(for date: Date) -> Int? {
        return range(of: .day, in: .month, for: date)?.count
    }
    
    /// 月の週数を取得する
    /// - parameter date: 対象日
    /// - returns: 週数
    func weeksInMonth(for date: Date) -> Int? {
        return range(of: .weekOfMonth, in: .month, for: date)?.count
    }
    
    /// 日付の曜日を取得する
    /// - parameter date: 対象日
    /// - returns: 日曜日→１、、、土曜日→７
    func dayOfWeek(for date: Date) -> Int? {
        return dateComponents([.weekday], from: date).weekday
    }
    
    /// 週の始まり日にちを取得する
    /// - parameter date: 対象月の日付
    /// - parameter weekOfMonth: 何週目かを数字で指定
    /// - returns; 指定した週の始まりの日にち
    func dayOfStartOfWeekInMonth(for date: Date, weekOfMonth: Int) -> Int? {
        // 月初の週だと前月の日付が抽出されてしまう場合があるので、1を返却
        if weekOfMonth == 1 {
            return 1
        }
        var components = dateComponents([.year, .month], from: date)
        components.weekOfMonth = weekOfMonth
        components.weekday = self.firstWeekday
        guard let weekStartDate = self.date(from: components) else {
            return nil
        }
        return self.component(.day, from: weekStartDate)
    }
}
