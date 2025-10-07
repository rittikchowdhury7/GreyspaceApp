//
//  RootView.swift
//  Greyspace
//
//  Created by Rittik Chowdhury on 2025-09-02.
//


import SwiftUI

struct RootView: View {
    enum Tab: Hashable { case today, tools, history, insights, support }
    @State private var selected: Tab = .today   // holds the active tab

    var body: some View {
        TabView(selection: $selected) {
            // ✅ pass the binding here
            TodayView(selectedTab: $selected)
                .tabItem { Label("Today", systemImage: "sun.max") }
                .tag(Tab.today)

            HistoryView()
                .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }
                .tag(Tab.history)

            InsightsView()
                .tabItem { Label("Insights", systemImage: "chart.line.uptrend.xyaxis") }
                .tag(Tab.insights)

            SettingsView()
                .tabItem { Label("Support", systemImage: "heart") }
                .tag(Tab.support)
        }
        .background(DS.Color.background.ignoresSafeArea())
    }
}
