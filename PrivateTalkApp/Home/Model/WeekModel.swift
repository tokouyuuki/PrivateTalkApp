//
//  WeekModel.swift
//  PrivateTalkApp
//
//  Created by 都甲裕希 on 2024/08/28.
//

import Foundation
import SwiftUICore

struct MonthModel: Identifiable {
    // ID（年月文字列）
    let id: Date
    // WeekModels
    let weekModels: [WeekModel]
}

struct WeekModel: Identifiable {
    let id = UUID()
    // 表示する日付のリスト
    let displayDates: [String]
    // １週間分のイベント
    let eventLabelModels: [[EventLabelModel]]
    
    init(dateStrings: [String], eventLabelModels: [[EventLabelModel]]) {
        self.displayDates = dateStrings
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
    // イベントの色
    let color: Color
}

enum EventDisplayType {
    // 予定を表示
    case full
    // 予定を省略表示（例　"+3"など）
    case overflow
    // 予定なし（空白）
    case none
}
