//
//  NotificationService.swift
//  Greyspace
//
//  Created by Rittik Chowdhury on 2025-09-02.
//

import Foundation
import UserNotifications

enum ReminderTime: String, CaseIterable, Identifiable {
    case morning, afternoon, evening
    var id: String { rawValue }

    var hour: Int {
        switch self {
        case .morning: return 9
        case .afternoon: return 14
        case .evening: return 20
        }
    }
}

struct NotificationService {
    static func requestAuthorization() async {
        let center = UNUserNotificationCenter.current()
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .badge, .sound])
            if !granted { print("Notifications not granted.") }
        } catch {
            print("Notification auth error: \(error)")
        }
    }

    static func scheduleDaily(reminder: ReminderTime, id: String) {
        let content = UNMutableNotificationContent()
        content.title = "60-second check-in"
        content.body = "One breath. Mood 1–5. One thought to reframe."
        content.sound = .default

        var date = DateComponents()
        date.hour = reminder.hour
        date.minute = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    static func clearAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
}
