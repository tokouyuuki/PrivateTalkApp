//
//  DateExtension.swift
//  PrivateTalkApp
//
//  Created by 都甲裕希 on 2025/04/02.
//

import Foundation

extension Date {
    
    // 日にち
    var day: Int {
        return Calendar.current.component(.day, from: self)
    }
    
    // 曜日（日曜日→１、、、土曜日→７）
    var dayOfWeek: Int {
        return Calendar.current.component(.weekday, from: self)
    }
    
    // 分と秒を00にしたDateを返す
    var roundedToHour: Date? {
        let calendar = Calendar.current
        return calendar.date(bySettingHour: calendar.component(.hour, from: self),
                             minute: 0,
                             second: 0,
                             of: self)
    }
    
    /// 任意の時間数を追加した Date を返す
    func addHours(_ hours: Int) -> Date? {
        return Calendar.current.date(byAdding: .hour,
                                     value: hours,
                                     to: self)
    }
}
