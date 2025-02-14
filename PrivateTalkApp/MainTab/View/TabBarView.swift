//
//  TabBarView.swift
//  PrivateTalkApp
//
//  Created by 都甲裕希 on 2024/08/10.
//

import SwiftUI

// MARK: - TabBarView
struct TabBarView: View {
    
    init() {
        // デフォルトのTabbarは使用しないので隠しておく
        UITabBar.appearance().isHidden = true
    }
    
    @State var currentTab: Tab = .home
    
    var body: some View {
        VStack(spacing: 8.0) {
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
        HStack(spacing: 8.0) {
            ForEach(Tab.allCases, id: \.hashValue) { tab in
                Button {
                    // 選択されたタブをデフォルトのタブに設定する
                    currentTab = tab
                } label: {
                    VStack(spacing: 5.0) {
                        Image(systemName: tab.imageName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 25.0, height: 25.0)
                            .foregroundStyle(currentTab == tab ? Color.primary : .gray)
                        Text(tab.tabText)
                            .font(.caption)
                            .foregroundStyle(Color.primary)
                    }
                    .frame(maxWidth: .infinity)
                }
                .disabled(currentTab == tab)
            }
        }
    }
}

#Preview {
    TabBarView()
}
