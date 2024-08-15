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
    case news
    case setting
}

// MARK: - Constants
private struct Constants {
    static let homeViewImageName = "house.fill"
    static let homeViewTabBerText = "ホーム"
    static let talkViewImageName = "message.badge.filled.fill.rtl"
    static let talkViewTabBerText = "トーク"
    static let newsViewImageName = "newspaper.fill"
    static let newsViewTabBerText = "ニュース"
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
        case .news:
            return Constants.newsViewImageName
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
        case .news:
            return Constants.newsViewTabBerText
        case .setting:
            return Constants.settingViewTabBerText
        }
    }
}
