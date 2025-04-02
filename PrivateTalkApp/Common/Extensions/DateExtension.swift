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
}
