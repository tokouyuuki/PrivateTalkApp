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
    // １週間分のイベント
    let eventLabelModels: [[EventLabelModel]]
    
    init(dateStringList: [String], eventLabelModels: [[EventLabelModel]]) {
        self.displayDateList = dateStringList
        self.eventLabelModels = eventLabelModels
    }
}

struct EventLabelModel: Identifiable {
    let id = UUID()
    // 表示するイベントのタイプ
    let eventDisplayType: EventDisplayType
    // イベントの識別子
    let eventIdList: [String]
    // イベントを表示するラベルの長さ
    let length: Int
    // 表示するイベントのタイトル
    let title: String
}

enum EventDisplayType {
    // 予定を表示
    case full
    // 予定を省略表示（例　"+3"など）
    case overflow
    // 予定なし（空白）
    case none
}
