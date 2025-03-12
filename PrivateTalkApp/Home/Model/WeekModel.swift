//
//  WeekModel.swift
//  PrivateTalkApp
//
//  Created by 都甲裕希 on 2024/08/28.
//

import Foundation
import SwiftUICore

// MARK: - 月のモデル
struct MonthModel: Identifiable {
    var id: String { yearMonthString }
    // 年月文字列
    let yearMonthString: String
    // １週間ごとの週モデル
    let weekModels: [WeekModel]
    
    init(yearMonthString: String?, weekModels: [WeekModel]) {
        self.yearMonthString = yearMonthString ?? String.empty
        self.weekModels = weekModels
    }
}

// MARK: - 週のモデル
struct WeekModel: Identifiable {
    var id: String { displaydays.last ?? String.empty }
    // 表示する日付のリスト
    let displaydays: [String]
    // 表示するイベント
    let eventLabelModel: [[EventLabelModel]]
}

// MARK: - イベントのモデル
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
