//
//  CalendarModel.swift
//  PrivateTalkApp
//
//  Created by 都甲裕希 on 2024/08/28.
//

import Foundation

struct CalendarModel {
    
    private struct Constants {
        static let YEAR_MONTH_DATE_FORMAT_KEY = "year_month_date_format"
    }
    
    // カレンダーに表示する時刻（UTC）
    let displayDate: Date?
    
    init(date: Date?) {
        self.displayDate = date
    }
    
    // カレンダーに表示する年月文字列
    var displayYearMonthString: String {
        let yearMonthString = DateUtilities.convertDateToString(date: self.displayDate,
                                                                format: Constants.YEAR_MONTH_DATE_FORMAT_KEY)
        
        return yearMonthString ?? String.empty
    }
}
