//
//  Tab.swift
//  PrivateTalkApp
//
//  Created by 都甲裕希 on 2024/08/10.
//

import Foundation
enum Tab: CaseIterable {
    case home
    case talk
    case setting
}

// MARK: - Constants
private struct Constants {
    static let homeViewImageName = "house.fill"
    static let homeViewTabBerText = "ホーム"
    static let talkViewImageName = "message.badge.filled.fill.rtl"
    static let talkViewTabBerText = "トーク"
    static let settingViewImageName = "gearshape.fill"
    static let settingViewTabBerText = "設定"
}

// MARK: - extension
extension Tab {
    /// タブバーに表示するイメージ名を返すメソッド
    /// Return: イメージ名
    func imageName() -> String {
        switch self {
        case .home:
            return Constants.homeViewImageName
        case .talk:
            return Constants.talkViewImageName
        case .setting:
            return Constants.settingViewImageName
        }
    }
    
    /// タブバーに表示するタブのテキストを返すメソッド
    /// Return: タブ名
    func tabText() -> String {
        switch self {
        case .home:
            return Constants.homeViewTabBerText
        case .talk:
            return Constants.talkViewTabBerText
        case .setting:
            return Constants.settingViewTabBerText
        }
    }
}
