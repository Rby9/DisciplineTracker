import Foundation
import SwiftData

@main
struct Checks {
    struct CheckError: Error { let message: String }

    static func expect(_ condition: @autoclosure () -> Bool, _ message: String) throws {
        if !condition() { throw CheckError(message: message) }
    }

    static func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 0,
                     calendar: Calendar) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }

    @MainActor static func main() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Bucharest")!
        let first = date(2026, 9, 7, calendar: calendar)
        let last = date(2026, 9, 13, calendar: calendar)
        let selected = try RecurrenceSchedule.dates(from: first, through: last, hour: 12,
                                                    minute: 0, weekdays: [2, 4, 6], calendar: calendar)
        try expect(selected.count == 3, "Mon/Wed/Fri must create exactly three tasks")
        try expect(selected.map { calendar.component(.weekday, from: $0) } == [2, 4, 6],
                   "Selected weekdays must match")
        let noon = date(2026, 9, 7, 12, calendar: calendar)
        let after = try RecurrenceSchedule.dates(from: first, through: last, hour: 12, minute: 0,
                                                weekdays: Set(1...7), after: noon,
                                                excludingDay: date(2026, 9, 9, calendar: calendar),
                                                calendar: calendar)
        try expect(after.count == 5 && after.allSatisfy { $0 > noon }, "No past or duplicate original day")
        for (month, day) in [(3, 28), (10, 24)] {
            let start = date(2026, month, day, calendar: calendar)
            let end = calendar.date(byAdding: .day, value: 2, to: start)!
            let dates = try RecurrenceSchedule.dates(from: start, through: end, hour: 12,
                                                     minute: 0, weekdays: Set(1...7), calendar: calendar)
            try expect(dates.count == 3 && dates.allSatisfy { calendar.component(.hour, from: $0) == 12 },
                       "Noon must stay noon across both DST changes")
        }
        let spring = date(2026, 3, 29, calendar: calendar)
        let nonexistent = try RecurrenceSchedule.dates(from: spring, through: spring, hour: 3,
                                                       minute: 30, weekdays: Set(1...7), calendar: calendar)
        try expect(nonexistent.count == 1 && calendar.isDate(nonexistent[0], inSameDayAs: spring),
                   "Nonexistent spring time must resolve within the selected day")
        let autumn = date(2026, 10, 25, calendar: calendar)
        let repeated = try RecurrenceSchedule.dates(from: autumn, through: autumn, hour: 3,
                                                    minute: 30, weekdays: Set(1...7), calendar: calendar)
        try expect(repeated.count == 1, "Repeated autumn hour must not duplicate a task")
        let leap = try RecurrenceSchedule.dates(from: date(2028, 2, 28, calendar: calendar),
                                               through: date(2028, 3, 1, calendar: calendar),
                                               hour: 12, minute: 0, weekdays: Set(1...7), calendar: calendar)
        try expect(leap.count == 3, "Leap day must be included")
        let yearChange = try RecurrenceSchedule.dates(from: date(2026, 12, 31, calendar: calendar),
                                                     through: date(2027, 1, 1, calendar: calendar),
                                                     hour: 12, minute: 0, weekdays: Set(1...7), calendar: calendar)
        try expect(yearChange.count == 2, "Year boundary must be included")
        for months in [1, 3, 4, 6] {
            let end = RecurrenceSchedule.lastDay(starting: first, months: months, calendar: calendar)
            let anniversary = calendar.date(byAdding: .month, value: months, to: first)!
            try expect(calendar.date(byAdding: .day, value: 1, to: end) == anniversary,
                       "Duration must end the day before the month anniversary")
        }
        do {
            _ = try RecurrenceSchedule.dates(from: last, through: first, hour: 12, minute: 0,
                                             weekdays: [2], calendar: calendar)
            throw CheckError(message: "Reversed date range was accepted")
        } catch RecurrenceSchedule.ScheduleError.invalidRange {}
        do {
            _ = try RecurrenceSchedule.dates(from: first, through: last, hour: 12, minute: 0,
                                             weekdays: [], calendar: calendar)
            throw CheckError(message: "Empty weekdays were accepted")
        } catch RecurrenceSchedule.ScheduleError.noWeekdays {}
        print("PASS: recurrence dates, cutoff, exclusions, DST, leap day, durations, invalid input")

        let store = URL(fileURLWithPath: CommandLine.arguments[1])
        let container = try ModelContainer(for: TaskItem.self, TaskSeries.self, JournalEntry.self,
                                           configurations: ModelConfiguration(url: store))
        let context = container.mainContext
        let legacyTasks = try context.fetch(FetchDescriptor<TaskItem>())
        try expect(legacyTasks.count == 2, "Migration must preserve tasks")
        try expect(legacyTasks.first { $0.title == "Legacy pending" }?.status == .pending,
                   "Legacy false maps to Pending")
        try expect(legacyTasks.first { $0.title == "Legacy completed" }?.status == .completed,
                   "Legacy true maps to Completed")
        let journals = try context.fetch(FetchDescriptor<JournalEntry>())
        try expect(journals.first?.note == "Keep my journal", "Migration must preserve journal")
        let routines = try context.fetch(FetchDescriptor<TaskSeries>())
        try expect(routines.count == 1 && routines[0].excludedDayKeys == nil,
                   "Migration must preserve existing routine")
        try expect(legacyTasks.allSatisfy { $0.reminderOffsets == nil && $0.effectiveReminderOffsets == [10, 0, -15] },
                   "Legacy tasks retain all three old reminders")
        try expect(routines[0].effectiveReminderOffsets == [10, 0, -15], "Legacy routines retain reminders")
        try expect(legacyTasks.allSatisfy { $0.snoozedUntil == nil && $0.reminderOverride == nil },
                   "New optional fields default safely")
        try expect(ReminderPolicy.normalized([30, 10, 30, 0, -15, -20, 999999]) == [30, 10, 0, -15],
                   "Reminder offsets are unique and bounded")
        let midnight = first.addingTimeInterval(15 * 60)
        let earlier = ReminderPolicy.fireDate(start: midnight, offset: 30)
        try expect(calendar.component(.hour, from: earlier) == 23 && calendar.component(.minute, from: earlier) == 45,
                   "Reminder before midnight belongs to the previous day")
        for start in [spring, autumn] {
            let reminder = ReminderPolicy.fireDate(start: start.addingTimeInterval(4 * 3600), offset: 120)
            try expect(start.addingTimeInterval(4 * 3600).timeIntervalSince(reminder) == 7200,
                       "Offsets represent elapsed minutes across DST")
        }
        print("PASS: legacy migration, reminder normalization and date boundaries")

        let original = TaskItem(title: "Conversion source", category: .food,
                                startTime: noon, isCompleted: false, notes: "Original notes")
        original.setStatus(.skipped)
        let originalID = original.id
        context.insert(original)
        try context.save()
        let series = try RoutineConversion.create(for: original, firstDay: first, lastDay: last,
                                                   hour: 12, minute: 0, weekdays: Set(1...7),
                                                   in: context, now: first, calendar: calendar, reminderOffsets: [30, 5])
        let linked = try context.fetch(FetchDescriptor<TaskItem>()).filter { $0.seriesID == series.id }
        try expect(series.effectiveReminderOffsets == [30, 5], "Routine stores new offsets")
        try expect(original.effectiveReminderOffsets == [10, 0, -15] && original.reminderOverride == true,
                   "Conversion keeps original reminder choices")
        try expect(linked.filter { $0.id != originalID }.allSatisfy { $0.effectiveReminderOffsets == [30, 5] },
                   "Future occurrences receive selected offsets")
        try expect(linked.count == 7, "Conversion keeps one original plus six future occurrences")
        try expect(original.id == originalID && original.startTime == noon && original.isSkipped,
                   "Conversion must preserve original identity, time and status")
        try expect(original.notes == "Original notes", "Conversion must preserve notes")
        let sameDay = linked.filter { calendar.isDate($0.startTime, inSameDayAs: noon) }
        try expect(sameDay.count == 1, "Conversion must not duplicate original day")
        do {
            _ = try RoutineConversion.create(for: original, firstDay: first, lastDay: last,
                                              hour: 12, minute: 0, weekdays: Set(1...7),
                                              in: context, now: first, calendar: calendar)
            throw CheckError(message: "A second conversion was accepted")
        } catch RoutineConversion.ConversionError.alreadyRecurring {}
        original.snoozedUntil = noon.addingTimeInterval(600)
        original.snoozedStartTime = noon
        original.setStatus(.completed)
        try expect(original.snoozedUntil == nil && original.snoozedStartTime == nil,
                   "Completing cancels a snooze")
        try expect(original.isCompleted && !original.isSkipped && !original.isPending, "Completed is exclusive")
        original.setStatus(.pending)
        try expect(original.isPending && !original.isCompleted && !original.isSkipped, "Pending is exclusive")
        original.setStatus(.skipped)
        original.reminderOffsets = []
        series.excludedDayKeys = [JournalEntry.key(for: last)]
        try context.save()
        let freshContext = ModelContext(container)
        let persisted = try freshContext.fetch(FetchDescriptor<TaskItem>()).first { $0.id == originalID }
        try expect(persisted?.isSkipped == true, "Skipped must persist after a fresh fetch")
        let savedRoutine = try freshContext.fetch(FetchDescriptor<TaskSeries>()).first { $0.id == series.id }
        try expect(savedRoutine?.excludedDayKeys?.count == 1, "Exclusion must persist")
        try expect(persisted?.reminderOffsets == [] && persisted?.effectiveReminderOffsets == [],
                   "Disabled reminders persist as an empty array, not legacy defaults")
        try expect(savedRoutine?.effectiveReminderOffsets == [30, 5], "Routine reminders persist")
        print("PASS: conversion identity, no duplicates, status exclusivity and persistence")
        print("All native checks passed.")
    }
}
