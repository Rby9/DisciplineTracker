//
//  JournalEntry.swift
//  DisciplineTracker
//
//  Created by Robert Balaban on 6/9/26.
//


import Foundation
import SwiftData

@Model
class JournalEntry {

    // MARK: - Properties

    @Attribute(.unique)
    var dayKey: String

    var date: Date
    var note: String
    var moodRaw: String?
    var updatedAt: Date

    // MARK: - Initialization

    init(
        date: Date,
        note: String,
        moodRaw: String?
    ) {
        self.dayKey = Self.key(for: date)
        self.date = date
        self.note = note
        self.moodRaw = moodRaw
        self.updatedAt = Date()
    }

    // MARK: - Day Identifier

    static func key(for date: Date) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current

        let parts = calendar.dateComponents(
            [.era, .year, .month, .day],
            from: date
        )

        return "\(parts.era ?? 1)-\(parts.year ?? 0)-\(parts.month ?? 0)-\(parts.day ?? 0)"
    }
}


// MARK: - Mood

enum JournalMood: String, CaseIterable {
    case low = "Low"
    case tired = "Tired"
    case okay = "Okay"
    case good = "Good"
    case great = "Great"

    var emoji: String {
        switch self {
        case .low:
            return "😔"
        case .tired:
            return "😴"
        case .okay:
            return "😐"
        case .good:
            return "🙂"
        case .great:
            return "😄"
        }
    }
}