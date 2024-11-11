//
//  Calendar.swift
//  PrivateTalkApp
//
//  Created by 都甲裕希 on 2024/11/07.
//

import Foundation

extension Calendar {
    
    /// 月の開始日を取得する
    /// - parameter date: 対象日
    /// - returns: 開始日
    func startOfMonth(for date: Date) -> Date? {
        let components = dateComponents([.year, .month], from: date)
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
    
    /// 月の開始日の曜日を取得する
    /// - parameter date: 対象日
    /// - returns: 日曜日→１、、、土曜日→７
    func firstWeekOfMonth(for date: Date) -> Int? {
        return dateComponents([.weekday], from: date).weekday
    }
}
