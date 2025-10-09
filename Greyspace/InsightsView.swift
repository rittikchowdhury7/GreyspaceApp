//
//  InsightsView.swift
//  Greyspace
//
//  Created by Rittik Chowdhury on 2025-09-02.
//


import SwiftUI
import SwiftData
import Charts

struct InsightsView: View {
    @Environment(\.calendar) private var calendar
    @Query(sort: \JournalEntry.date, order: .reverse, animation: .default)
    private var entries: [JournalEntry]
    let showSettings: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: DS.Spacing.lg) {

                    // Mood trend
                    Card {
                        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                            HStack {
                                Text("Weekly mood trend")
                                    .font(DS.Typography.heading())
                                Spacer()
                                if let last = entries.first?.date {
                                    Text("Updated \(last, style: .date)")
                                        .font(DS.Typography.caption())
                                        .foregroundStyle(DS.Color.muted)
                                }
                            }

                            if weekPoints.isEmpty {
                                EmptyMini(text: "No data yet — log a check-in to see trends.")
                            } else {
                                Chart(weekPoints) { p in
                                    LineMark(
                                        x: .value("Day", p.label),
                                        y: .value("Mood", p.value)
                                    )
                                    .interpolationMethod(.catmullRom)

                                    PointMark(
                                        x: .value("Day", p.label),
                                        y: .value("Mood", p.value)
                                    )
                                }
                                .chartYScale(domain: 1...5)
                                .frame(height: 180)
                                .padding(.top, DS.Spacing.xs)

                                  HStack {
                                      LegendDot(color: DS.Color.accent)
                                    Text("1 = low, 5 = high")
                                        .font(DS.Typography.caption())
                                        .foregroundStyle(DS.Color.muted)
                                    Spacer()
                                    Text(avgMoodText)
                                        .font(DS.Typography.caption())
                                        .foregroundStyle(DS.Color.muted)
                                }
                            }
                        }
                    }

                    // This week summary
                    Card {
                        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                            Text("This week at a glance")
                                .font(DS.Typography.heading())

                            if weekEntries.isEmpty {
                                EmptyMini(text: "No entries yet this week.")
                            } else {
                                SummaryRow(label: "Check-ins", value: "\(weekEntries.count)")
                                SummaryRow(label: "Avg mood", value: String(format: "%.1f / 5", avgMood))
                                SummaryRow(label: "Avg anxiety", value: String(format: "%.1f / 10", avgAnxiety))
                                if let best = bestGratitudeSnippet {
                                    SummaryRow(label: "Bright spot", value: best)
                                }
                            }
                        }
                    }

                    // Streak & cadence
                    Card {
                        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                            Text("Consistency")
                                .font(DS.Typography.heading())
                            HStack(spacing: DS.Spacing.lg) {
                                StatPill(title: "Current streak", value: "\(currentStreak) days")
                                StatPill(title: "Days this month", value: "\(daysThisMonth) d")
                                StatPill(title: "Avg per week", value: String(format: "%.1f", checksPerWeek))
                            }
                            .padding(.top, DS.Spacing.xs)
                        }
                    }

                    // Anxiety range
                    Card {
                        VStack(alignment: .leading, spacing: DS.Spacing.sm) {
                            Text("Anxiety range (last 30 days)")
                                .font(DS.Typography.heading())
                            if last30.isEmpty {
                                EmptyMini(text: "Log a few entries to see a range.")
                            } else {
                                let minA = last30.map(\.anxiety).min() ?? 0
                                let maxA = last30.map(\.anxiety).max() ?? 0
                                ProgressView(value: Double(maxA), total: 10)
                                    .tint(DS.Color.accent)
                                HStack {
                                    Text("Min: \(minA)/10")
                                    Spacer()
                                    Text("Max: \(maxA)/10")
                                }
                                .font(DS.Typography.caption())
                                .foregroundStyle(DS.Color.muted)
                            }
                        }
                    }
                }
                .padding(.horizontal, DS.Spacing.lg)
                .padding(.bottom, DS.Spacing.xl)
            }
            .navigationTitle("Insights")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showSettings()
                    } label: {
                        Image(systemName: "gearshape.fill")
                    }
                    .accessibilityLabel(Text(String(localized: "Settings")))
                }
            }
        }
    }
}

private extension InsightsView {
    // MARK: - Card helpers / small views

    struct Card<Content: View>: View {
        @ViewBuilder var content: Content
        var body: some View {
            SurfaceCard {
                VStack(alignment: .leading, spacing: DS.Spacing.md) {
                    content
                }
            }
        }
    }

    struct EmptyMini: View {
        let text: String
        var body: some View {
            Text(text)
                .font(DS.Typography.body())
                .foregroundStyle(DS.Color.muted)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, DS.Spacing.sm)
        }
    }

    struct LegendDot: View {
        var color: Color
        var body: some View {
            Circle().fill(color).frame(width: 8, height: 8)
        }
    }

    struct StatPill: View {
        let title: String
        let value: String
        var body: some View {
            VStack(alignment: .leading, spacing: 2) {
                Text(value).font(DS.Typography.heading())
                Text(title).font(DS.Typography.caption()).foregroundStyle(DS.Color.muted)
            }
            .padding(.vertical, DS.Spacing.md)
            .padding(.horizontal, DS.Spacing.md)
            .background(DS.Color.surface.opacity(0.18), in: RoundedRectangle(cornerRadius: DS.Radius.md))
        }
    }

    // MARK: - Data slices

    struct Point: Identifiable {
        let id = UUID()
        let date: Date
        let label: String
        let value: Double
    }

    var weekEntries: [JournalEntry] {
        guard let start = calendar.dateInterval(of: .weekOfYear, for: Date())?.start else { return [] }
        return entries.filter { $0.date >= start }
    }

    var weekPoints: [Point] {
        // Build points for the current week (Sun–Sat based on user calendar)
        guard let interval = calendar.dateInterval(of: .weekOfYear, for: Date()) else { return [] }
        let days = stride(from: 0, through: 6, by: 1).compactMap {
            calendar.date(byAdding: .day, value: $0, to: interval.start)
        }
        return days.map { day in
            let dayEntries = entries.filter { calendar.isDate($0.date, inSameDayAs: day) }
            let avg = dayEntries.isEmpty ? nil : Double(dayEntries.map(\.mood).reduce(0, +)) / Double(dayEntries.count)
            let label = DateFormatter.shortWeekday.string(from: day)
            return Point(date: day, label: label, value: avg ?? .nan)
        }
        .filter { !$0.value.isNaN }
        .sorted(by: { $0.date < $1.date })
    }

    var avgMood: Double {
        guard !weekEntries.isEmpty else { return 0 }
        return Double(weekEntries.map(\.mood).reduce(0, +)) / Double(weekEntries.count)
    }

    var avgAnxiety: Double {
        guard !weekEntries.isEmpty else { return 0 }
        return Double(weekEntries.map(\.anxiety).reduce(0, +)) / Double(weekEntries.count)
    }

    var avgMoodText: String {
        weekEntries.isEmpty ? "—" : "Avg mood: " + String(format: "%.1f / 5", avgMood)
    }

    var last30: [JournalEntry] {
        guard let from = calendar.date(byAdding: .day, value: -30, to: Date()) else { return [] }
        return entries.filter { $0.date >= from }
    }

    var currentStreak: Int {
        // Count back from today, consecutive days with ≥1 entry
        var count = 0
        var day = calendar.startOfDay(for: Date())
        let entryDays = Set(entries.map { calendar.startOfDay(for: $0.date) })
        while entryDays.contains(day) {
            count += 1
            guard let prev = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = prev
        }
        return count
    }

    var daysThisMonth: Int {
        guard let start = calendar.dateInterval(of: .month, for: Date())?.start else { return 0 }
        let entryDays = Set(entries.map { calendar.startOfDay(for: $0.date) })
        var day = start
        var count = 0
        while day <= Date() {
            if entryDays.contains(day) { count += 1 }
            guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
            day = next
        }
        return count
    }

    var checksPerWeek: Double {
        guard let first = entries.last?.date else { return 0 }
        let weeks = max(1, calendar.dateComponents([.weekOfYear], from: first, to: Date()).weekOfYear ?? 1)
        return Double(entries.count) / Double(weeks)
    }
    
    var bestGratitudeSnippet: String? {
        // Pick the most recent non-empty gratitude item from this week
        for entry in weekEntries.sorted(by: { $0.date > $1.date }) {
            if let g = entry.gratitude.first(where: { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) {
                return g
            }
        }
        return nil
    }
}

private extension DateFormatter {
    static let shortWeekday: DateFormatter = {
        let f = DateFormatter()
        f.locale = .current
        f.dateFormat = "E" // Mon, Tue, ...
        return f
    }()
}
