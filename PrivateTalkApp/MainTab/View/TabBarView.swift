//
//  TabBarView.swift
//  PrivateTalkApp
//
//  Created by 都甲裕希 on 2024/08/10.
//

import SwiftUI

// MARK: - Constants
private struct Constants {
    static let TAB_BAR_VIEW_SPACING = 0.0
    static let ITEM_IN_TAB_SPACING = 5.0
    static let IMAGE_IN_TAB_WIDTH = 25.0
    static let IMAGE_IN_TAB_HEIGHT = 25.0
    static let TAB_HEIGHT = 30.0
    static let TAB_VERTICAL = 10.0
}

// MARK: - TabBarView
struct TabBarView: View {
    
    init() {
        // デフォルトのTabbarは使用しないので隠しておく
        UITabBar.appearance().isHidden = true
    }
    
    @State var currentTab: Tab = .home
    
    var body: some View {
        VStack(spacing: Constants.TAB_BAR_VIEW_SPACING) {
            TabView(selection: $currentTab) {
                HomeView().tag(Tab.home)
                TalkView().tag(Tab.talk)
                NewsView().tag(Tab.news)
                SettingView().tag(Tab.setting)
            }
            Divider()
            CustomTabBar(currentTab: $currentTab)
        }
    }
}

// MARK: - CustomTabBar
private struct CustomTabBar: View {
    
    @Binding var currentTab: Tab
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: Constants.TAB_BAR_VIEW_SPACING) {
                ForEach(Tab.allCases, id: \.hashValue) { tab in
                    Button {
                        // 選択されたタブをデフォルトのタブに設定する
                        currentTab = tab
                    } label: {
                        VStack(spacing: Constants.ITEM_IN_TAB_SPACING) {
                            Image(systemName: tab.imageName)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: Constants.IMAGE_IN_TAB_WIDTH, 
                                       height: Constants.IMAGE_IN_TAB_HEIGHT)
                                .foregroundStyle(currentTab == tab ? Color.foreground : .gray)
                            Text(tab.tabText)
                                .font(.caption)
                                .foregroundStyle(Color.foreground)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(currentTab == tab)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .frame(height: Constants.TAB_HEIGHT)
        .padding(.vertical, Constants.TAB_VERTICAL)
    }
}

#Preview {
    TabBarView()
}
