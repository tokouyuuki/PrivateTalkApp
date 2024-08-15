//
//  TabBarView.swift
//  PrivateTalkApp
//
//  Created by 都甲裕希 on 2024/08/10.
//

import SwiftUI

struct TabBarView: View {
    
    init() {
        // デフォルトのTabbarは使用しないので隠しておく
        UITabBar.appearance().isHidden = true
    }
    
    @State var currentTab: Tab = .home
    
    var body: some View {
        VStack(spacing: 0) {
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

/// カスタムタブバー
struct CustomTabBar: View {
    
    @Binding var currentTab: Tab
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                ForEach(Tab.allCases, id: \.hashValue) { tab in
                    Button {
                        // 選択されたタブをデフォルトのタブに設定する
                        currentTab = tab
                    } label: {
                        VStack(spacing: 5) {
                            Image(systemName: tab.imageName())
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 25, height: 25)
                                .foregroundColor(currentTab == tab ? .iconBlack : .gray)
                            Text(tab.tabText())
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .disabled(currentTab == tab)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .frame(height: 30.0)
        .padding(.vertical, 10.0)
    }
}

#Preview {
    TabBarView()
}
