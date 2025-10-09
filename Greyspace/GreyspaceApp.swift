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
    @AppStorage(AppLanguage.storageKey) private var appLanguageCode: String = AppLanguage.defaultCode

    var body: some Scene {
        WindowGroup {
            RootView()
                .appTheme()
                .environment(\.locale, AppLanguage.locale(for: appLanguageCode))
                .onAppear {
                    AppLanguage.applySelection(appLanguageCode)
                }
        }
        .modelContainer(for: [JournalEntry.self, ThoughtRecord.self, PressureSlip.self])
    }
}



