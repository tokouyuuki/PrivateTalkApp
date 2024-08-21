//
//  Tab.swift
//  PrivateTalkApp
//
//  Created by 都甲裕希 on 2024/08/10.
//

import Foundation

// MARK: - enum
enum Tab: CaseIterable {
    case home
    case talk
    case news
    case setting
}

// MARK: - Constants
private struct Constants {
    static let HOME_VIEW_IMAGE_NAME = "house.fill"
    static let HOME_VIEW_TAB_BAR_TEXT = "ホーム"
    static let TALK_VIEW_IMAGE_NAME = "message.badge.filled.fill.rtl"
    static let TALK_VIEW_TAB_BAR_TEXT = "トーク"
    static let NEWS_VIEW_IMAGE_NAME = "newspaper.fill"
    static let NEWS_VIEW_TAB_BAR_TEXT = "ニュース"
    static let SETTIMG_VIEW_IMAGE_NAME = "gearshape.fill"
    static let sSETTIMG_VIEW_TAB_BAR_TEXT = "設定"
}

// MARK: - extension
extension Tab {
    /// タブバーに表示するイメージ名を返すメソッド
    /// - returns: イメージ名
    func imageName() -> String {
        switch self {
        case .home:
            return Constants.HOME_VIEW_IMAGE_NAME
        case .talk:
            return Constants.TALK_VIEW_IMAGE_NAME
        case .news:
            return Constants.NEWS_VIEW_IMAGE_NAME
        case .setting:
            return Constants.SETTIMG_VIEW_IMAGE_NAME
        }
    }
    
    /// タブバーに表示するタブのテキストを返すメソッド
    /// - returns: タブ名
    func tabText() -> String {
        switch self {
        case .home:
            return Constants.HOME_VIEW_TAB_BAR_TEXT
        case .talk:
            return Constants.TALK_VIEW_TAB_BAR_TEXT
        case .news:
            return Constants.NEWS_VIEW_TAB_BAR_TEXT
        case .setting:
            return Constants.sSETTIMG_VIEW_TAB_BAR_TEXT
        }
    }
}
