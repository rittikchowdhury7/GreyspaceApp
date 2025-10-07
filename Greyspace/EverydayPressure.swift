//
//  EverydayPressure.swift
//  Greyspace
//
//  Created by Rittik Chowdhury on 2025-09-21.
//


// EverydayPressure.swift
import Foundation

struct EverydayPressure: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let softerTake: String
}

enum PressureDeck {
    static let starter: [EverydayPressure] = [
        EverydayPressure(
            title: "Being the translator for family (calls, forms, appointments)",
            softerTake: "I’ve been resourceful for my family. It’s okay to pause, share the load, or ask for help when this role feels heavy."
        ),
        EverydayPressure(
            title: "Comparisons to ‘perfect’ cousins / kids",
            softerTake: "I can appreciate their path and still choose mine. Growth isn’t a race; my timeline is valid."
        ),
        EverydayPressure(
            title: "Pressure to choose a ‘stable’ career over what you love",
            softerTake: "Safety matters—and so does fulfillment. I can take small steps toward both without rejecting either."
        ),
        EverydayPressure(
            title: "Guilt when setting boundaries with family",
            softerTake: "Boundaries protect connection. Saying ‘not right now’ can be caring—for me and for us."
        ),
        EverydayPressure(
            title: "Expectations around dating/marrying within culture",
            softerTake: "I can honor tradition and still choose what’s healthy for me. Both love and culture deserve care."
        ),
        EverydayPressure(
            title: "Feeling responsible for parents’ sacrifices",
            softerTake: "Their sacrifices gave me options—not a debt I must repay. Living well is a form of gratitude."
        ),
        EverydayPressure(
            title: "Being ‘the strong one’ who can’t show stress",
            softerTake: "Strength can include asking for help. I’m allowed to need, feel, and rest."
        ),
        EverydayPressure(
            title: "Shame when mental health isn’t ‘a real thing’ at home",
            softerTake: "My feelings are real. I can care for my mind even if others learned different rules."
        ),
        EverydayPressure(
            title: "Balancing two sets of norms (home vs. outside)",
            softerTake: "It’s normal to feel mixed. I can take what serves me from each culture and grow my own way."
        ),
        EverydayPressure(
            title: "Money support expectations",
            softerTake: "Helping is caring; limits are caring too. I can plan support that doesn’t sink me."
        ),
        EverydayPressure(
            title: "Living at home longer than peers",
            softerTake: "Our paths differ. I can work toward my goals at a pace that fits my reality."
        ),
        EverydayPressure(
            title: "Fear of ‘disappointing’ the family",
            softerTake: "Disagreement isn’t betrayal. I can communicate honestly and still belong."
        ),
    ]
}