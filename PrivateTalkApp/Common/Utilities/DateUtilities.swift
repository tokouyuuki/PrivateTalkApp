//
//  DateUtilities.swift
//  PrivateTalkApp
//
//  Created by 都甲裕希 on 2024/08/22.
//

import Foundation

// MARK: - 日付のフォーマットや変換、計算、比較などを提供するクラス
struct DateUtilities {
    
    /// Dateをタイムスタンプに変換
    /// また、UTCからタイムゾーンに補正も行う
    /// - parameter date: タイムスタンプに変換したいDate
    /// - returns: タイムスタンプ
    static func convertDateToTimestamp(date: Date?) -> TimeInterval? {
        guard let date = date else {
            return nil
        }
        // 端末のローカルタイムゾーンとUTCの差分時間を取得
        let timeZoneOffset = TimeInterval(TimeZone.current.secondsFromGMT(for: date))
        // オフセットをプラスし、Dateをタイムスタンプに変換
        let localTimestamp = date.timeIntervalSince1970 + timeZoneOffset
        
        return localTimestamp
    }
    
    /// DateをStringに変換
    /// また、UTCからタイムゾーンに補正も行う
    /// - parameter date: Stringに変換したいDate
    /// - parameter format: フォーマット
    /// - returns: String
    static func convertDateToString(date: Date?, format: String) -> String? {
        guard let date = date else {
            return nil
        }
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.timeZone = TimeZone.current
        formatter.dateFormat = NSLocalizedString(format, comment: String.empty)
        
        return formatter.string(from: date)
        
    }
    
    /// StringをDateに変換
    /// - parameter dateString: Dateに変換したいString
    /// - parameter format: フォーマット
    /// - returns: Date
    static func convertStringToUtcDate(dateString: String?, format: String) -> Date? {
        guard let dateString = dateString else {
            return nil
        }
        let formatter = DateFormatter()
        formatter.locale = Locale.current
        formatter.dateFormat = format
        
        return formatter.date(from: dateString)
    }
}
