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
    var excludedDayKeys: [String]? = nil

    // nil preserves reminders from the previous app version; [] means disabled.
    var reminderOffsets: [Int]? = nil

    var effectiveReminderOffsets: [Int] {
        ReminderPolicy.normalized(reminderOffsets ?? ReminderPolicy.legacyOffsets)
    }

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