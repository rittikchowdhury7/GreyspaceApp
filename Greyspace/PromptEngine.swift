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
        // Escalate if low mood OR high anxiety
        if mood <= 2 || anxiety >= 7 {
            return .init(shouldSuggestCBT: true,
                         reason: "Mood low (\(mood)) or anxiety high (\(anxiety)).")
        }
        return .init(shouldSuggestCBT: false, reason: "Steady state.")
    }
}
