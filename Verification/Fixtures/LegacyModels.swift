import Foundation
import SwiftUI
import SwiftData

@Model
class TaskItem {

    // MARK: - Properties

    var id: UUID
    var title: String
    var category: TaskCategory
    var startTime: Date
    var isCompleted: Bool
    var notes: String

    // MARK: - Recurrence

    var seriesID: UUID? = nil
    var originalScheduledDate: Date? = nil

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        title: String,
        category: TaskCategory,
        startTime: Date,
        isCompleted: Bool,
        notes: String,
        seriesID: UUID? = nil,
        originalScheduledDate: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.startTime = startTime
        self.isCompleted = isCompleted
        self.notes = notes
        self.seriesID = seriesID
        self.originalScheduledDate = originalScheduledDate
    }
}


// MARK: - Task Category

enum TaskCategory: String, CaseIterable, Codable {

    case gym = "Gym"
    case food = "Food"
    case work = "Work"
    case sleep = "Sleep"
    case other = "Other"

    var color: Color {
        switch self {
        case .gym:
            return .red
        case .food:
            return .orange
        case .work:
            return .blue
        case .sleep:
            return .purple
        case .other:
            return .gray
        }
    }
}


//
//  TaskSeries.swift
//  DisciplineTracker
//
//  Created by Robert Balaban on 6/9/26.
//


import Foundation
import SwiftData

@Model
class TaskSeries {

    // MARK: - Properties

    var id: UUID
    var title: String
    var category: TaskCategory
    var notes: String

    var startDate: Date
    var endDate: Date

    var hour: Int
    var minute: Int

    // Calendar weekdays: Sunday = 1, Monday = 2, ...
    var weekdays: [Int]

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        title: String,
        category: TaskCategory,
        notes: String,
        startDate: Date,
        endDate: Date,
        hour: Int,
        minute: Int,
        weekdays: [Int]
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.notes = notes
        self.startDate = startDate
        self.endDate = endDate
        self.hour = hour
        self.minute = minute
        self.weekdays = weekdays
    }
}

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