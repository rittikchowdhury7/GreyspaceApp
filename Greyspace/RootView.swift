//
//  RootView.swift
//  Greyspace
//
//  Created by Rittik Chowdhury on 2025-09-02.
//


import SwiftUI

struct RootView: View {
    enum Tab: Hashable, CaseIterable {
        case today
        case history
        case insights
        case support
    }

    @State private var selected: Tab = .today

    private let tabs: [TabItem] = TabItem.all

    var body: some View {
        content(for: selected)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(DS.Color.background.ignoresSafeArea())
            .safeAreaInset(edge: .bottom) {
                CustomTabBar(selected: $selected, tabs: tabs)
            }
    }

    @ViewBuilder
    private func content(for tab: Tab) -> some View {
        switch tab {
        case .today:
            TodayView(selectedTab: $selected)
        case .history:
            HistoryView()
        case .insights:
            InsightsView()
        case .support:
            SettingsView()
        }
    }
}

private struct TabItem: Identifiable {
    let tab: RootView.Tab
    let icon: String
    let titleKey: LocalizedStringKey
    let accessibilityKey: LocalizedStringKey

    var id: RootView.Tab { tab }

    static let all: [TabItem] = [
        TabItem(tab: .today, icon: "sun.max.fill", titleKey: "tab.today", accessibilityKey: "tab.today.accessibility"),
        TabItem(tab: .history, icon: "clock.arrow.circlepath", titleKey: "tab.history", accessibilityKey: "tab.history.accessibility"),
        TabItem(tab: .insights, icon: "chart.line.uptrend.xyaxis", titleKey: "tab.insights", accessibilityKey: "tab.insights.accessibility"),
        TabItem(tab: .support, icon: "heart.fill", titleKey: "tab.support", accessibilityKey: "tab.support.accessibility")
    ]
}

private struct CustomTabBar: View {
    @Binding var selected: RootView.Tab
    let tabs: [TabItem]

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: DS.Spacing.sm) {
                ForEach(tabs) { item in
                    Button {
                        withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
                            selected = item.tab
                        }
                    } label: {
                        VStack(spacing: DS.Spacing.xs) {
                            Image(systemName: item.icon)
                                .font(.system(size: 18, weight: .semibold))
                                .frame(height: 20)

                            Text(item.titleKey)
                                .font(DS.Typography.caption())
                                .lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DS.Spacing.sm)
                        .padding(.horizontal, DS.Spacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: DS.Radius.md, style: .continuous)
                                .fill(selected == item.tab ? DS.Color.primary : DS.Color.surface.opacity(0.92))
                                .shadow(color: selected == item.tab ? DS.Color.primary.opacity(0.28) : DS.Color.background.opacity(0.0), radius: 10, x: 0, y: 6)
                        )
                        .foregroundStyle(selected == item.tab ? DS.Color.onPrimary : DS.Color.muted)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text(item.accessibilityKey))
                    .accessibilityAddTraits(selected == item.tab ? [.isSelected] : [])
                }
            }
            .padding(.vertical, DS.Spacing.sm)
            .padding(.horizontal, DS.Spacing.xl)
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.lg, style: .continuous)
                    .fill(DS.Color.surface.opacity(0.85))
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.Radius.lg, style: .continuous)
                            .stroke(DS.Color.muted.opacity(0.15), lineWidth: 1)
                    )
                    .shadow(color: DS.Color.background.opacity(0.6), radius: 18, x: 0, y: 6)
            )
            .padding(.horizontal, DS.Spacing.lg)
            .padding(.top, DS.Spacing.sm)
            .padding(.bottom, DS.Spacing.lg)
        }
        .frame(maxWidth: .infinity)
        .background(
            DS.Color.background
                .opacity(0.96)
                .ignoresSafeArea(edges: .bottom)
                .overlay(
                    LinearGradient(colors: [DS.Color.surface.opacity(0.25), .clear], startPoint: .top, endPoint: .bottom)
                        .frame(height: 1)
                        .frame(maxHeight: .infinity, alignment: .top)
                )
        )
    }
}
