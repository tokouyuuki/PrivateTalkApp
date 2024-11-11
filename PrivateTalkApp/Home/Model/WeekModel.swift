//
//  WeekModel.swift
//  PrivateTalkApp
//
//  Created by 都甲裕希 on 2024/08/28.
//

import Foundation

struct WeekModel: Identifiable {
    
    let id = UUID()
    
    // 表示する日付のリスト
    let displayDateList: [String]
    
    init(dateStringList: [String]) {
        self.displayDateList = dateStringList
    }
}
