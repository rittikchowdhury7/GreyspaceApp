//
//  PromptEngine.swift
//  Greyspace
//
//  Created by Rittik Chowdhury on 2025-09-02.
//

import Foundation

struct PromptDecision {
    let shouldSuggestCBT: Bool
    let reason: String
}

struct PromptEngine {
    static func decide(mood: Int, anxiety: Int) -> PromptDecision {
        let language = Localization.currentLanguage()
        // Escalate if low mood OR high anxiety
        if mood <= 2 || anxiety >= 7 {
            let format = Localization.string("prompt.reason.escalate",
                                             fallback: "Mood low (%d) or anxiety high (%d).",
                                             language: language)
            return .init(shouldSuggestCBT: true,
                         reason: String(format: format, mood, anxiety))
        }
        let steady = Localization.string("prompt.reason.steady",
                                         fallback: "Steady state.",
                                         language: language)
        return .init(shouldSuggestCBT: false, reason: steady)
    }
}
