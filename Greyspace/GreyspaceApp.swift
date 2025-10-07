//
//  GreyspaceApp.swift
//  Greyspace
//
//  Created by Rittik Chowdhury on 2025-09-02.
//

import SwiftUI
import SwiftData

@main
struct GreyspaceApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .appTheme()
        }
        .modelContainer(for: [JournalEntry.self, ThoughtRecord.self, PressureSlip.self])
    }
}



