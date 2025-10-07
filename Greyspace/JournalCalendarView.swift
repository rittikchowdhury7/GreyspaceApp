//
//  JournalCalendarView.swift
//  Greyspace
//
//  Created by Rittik Chowdhury on 2025-09-03.
//


import SwiftUI
import SwiftData

struct JournalCalendarView: View {
    @Environment(\.calendar) private var calendar
    @Environment(\.colorScheme) private var colorScheme

    // Pass your entries so we can mark days with check-ins
    let entries: [JournalEntry]

    // Navigate months (0 = current month)
    @State private var monthOffset: Int = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            weekdayHeader
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 8) {
                ForEach(days, id: \.self) { day in
                    if let day {
                        dayCell(day)
                    } else {
                        Color.clear.frame(height: 36)
                    }
                }
            }
        }
        .padding(12)
        .background(.secondary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Header (month, prev/next)
    private var header: some View {
        HStack {
            Button {
                withAnimation(.easeInOut) { monthOffset -= 1 }
            } label: { Image(systemName: "chevron.left") }

            Spacer()

            Text(monthTitle)
                .font(.headline)

            Spacer()

            Button {
                withAnimation(.easeInOut) { monthOffset += 1 }
            } label: { Image(systemName: "chevron.right") }
        }
    }

    // MARK: - Weekday row
    private var weekdayHeader: some View {
        let symbols = weekdaySymbols
        return HStack {
            ForEach(symbols, id: \.self) { s in
                Text(s)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.bottom, 2)
    }

    // MARK: - Day cell
    private func dayCell(_ date: Date) -> some View {
        let isToday = calendar.isDateInToday(date)
        let inThisMonth = calendar.isDate(date, equalTo: monthStart, toGranularity: .month)
        let checked = hasEntry(on: date)

        return VStack(spacing: 2) {
            Text("\(calendar.component(.day, from: date))")
                .font(.footnote)
                .fontWeight(isToday ? .semibold : .regular)
                .foregroundStyle(inThisMonth ? .primary : .secondary)

            if checked {
                Image(systemName: "checkmark.circle.fill")
                    .imageScale(.small)
            } else {
                Circle()
                    .fill(.clear)
                    .frame(width: 12, height: 12)
                    .overlay(
                        Circle()
                            .stroke(.quaternary, lineWidth: 1)
                            .opacity(isToday ? 1 : 0) // subtle ring for today when no checkin
                    )
            }
        }
        .frame(height: 36)
        .frame(maxWidth: .infinity)
        .padding(4)
        .background(
            Circle()
                .fill(.primary.opacity(0)) // transparent
                .frame(width: 12, height: 12)
        )
        .accessibilityLabel(Text("\(date, formatter: a11yFormatter): \(checked ? "Check-in" : "No check-in")"))
    }

    // MARK: - Helpers

    private var displayedMonth: Date {
        calendar.date(byAdding: .month, value: monthOffset, to: Date()) ?? Date()
    }

    private var monthStart: Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth)) ?? displayedMonth
    }

    private var monthEnd: Date {
        calendar.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart) ?? displayedMonth
    }

    private var monthTitle: String {
        let fmt = DateFormatter()
        fmt.calendar = calendar
        fmt.locale = .current
        fmt.dateFormat = "LLLL yyyy"
        return fmt.string(from: displayedMonth)
    }

    private var weekdaySymbols: [String] {
        // Start from the calendar's firstWeekday
        let symbols = calendar.veryShortWeekdaySymbols // ["S","M","T","W","T","F","S"]
        let first = calendar.firstWeekday - 1
        return Array(symbols[first...] + symbols[..<first])
    }

    // Create a grid of optional dates including leading blanks to align the first weekday
    private var days: [Date?] {
        var result: [Date?] = []
        let startWeekdayIndex = weekdayIndex(for: monthStart) // 0-based
        // leading blanks
        result.append(contentsOf: Array(repeating: nil, count: startWeekdayIndex))

        let range = calendar.range(of: .day, in: .month, for: monthStart) ?? 1..<31
        for day in range {
            if let d = calendar.date(byAdding: .day, value: day - 1, to: monthStart) {
                result.append(d)
            }
        }
        return result
    }

    private func weekdayIndex(for date: Date) -> Int {
        // Convert to 0-based index with firstWeekday respected
        let weekday = calendar.component(.weekday, from: date) // 1...7
        let first = calendar.firstWeekday // 1...7
        return (weekday - first + 7) % 7
    }

    private var entryDays: Set<Date> {
        // Normalize each entry date to start-of-day for fast membership checks
        let normalized = entries.map { calendar.startOfDay(for: $0.date) }
        return Set(normalized)
    }

    private func hasEntry(on date: Date) -> Bool {
        entryDays.contains(calendar.startOfDay(for: date))
    }

    private var a11yFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateStyle = .full
        f.timeStyle = .none
        return f
    }
}
