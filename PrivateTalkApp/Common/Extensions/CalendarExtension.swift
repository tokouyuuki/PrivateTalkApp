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
    
    /// ２つのDate間の日数を取得する
    /// - parameters: 比べたい日付
    func days(from date1: Date, to date2: Date) -> Int {
        return dateComponents([.day], from: startOfDay(for: date1), to: startOfDay(for: date2)).day ?? 0
    }
}
