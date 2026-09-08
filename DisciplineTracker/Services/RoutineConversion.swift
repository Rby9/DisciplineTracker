import Foundation
import SwiftData

@MainActor
enum RoutineConversion {
    enum ConversionError: LocalizedError {
        case alreadyRecurring, noFutureOccurrences
        var errorDescription: String? {
            switch self {
            case .alreadyRecurring: return "This task already belongs to a routine."
            case .noFutureOccurrences: return "There are no future occurrences for this schedule."
            }
        }
    }

    @discardableResult
    static func create(
        for task: TaskItem, firstDay: Date, lastDay: Date,
        hour: Int, minute: Int, weekdays: Set<Int>,
        in context: ModelContext, now: Date = Date(), calendar: Calendar = .current, reminderOffsets: [Int]? = nil
    ) throws -> TaskSeries {
        guard task.seriesID == nil else { throw ConversionError.alreadyRecurring }
        let dates = try RecurrenceSchedule.dates(
            from: firstDay, through: lastDay, hour: hour, minute: minute,
            weekdays: weekdays, after: now, excludingDay: task.startTime, calendar: calendar
        )
        guard !dates.isEmpty else { throw ConversionError.noFutureOccurrences }
        // Save any pre-existing edits before starting this atomic change.
        try context.save()
        do {
            let series = TaskSeries(
                title: task.title, category: task.category, notes: task.notes,
                startDate: calendar.startOfDay(for: firstDay), endDate: calendar.startOfDay(for: lastDay),
                hour: hour, minute: minute, weekdays: weekdays.sorted()
            )
            let offsets = ReminderPolicy.normalized(reminderOffsets ?? task.effectiveReminderOffsets)
            series.reminderOffsets = offsets
            context.insert(series)
            task.seriesID = series.id
            task.originalScheduledDate = task.startTime
            task.reminderOverride = task.effectiveReminderOffsets != offsets
            for date in dates {
                let occurrence = TaskItem(
                    title: task.title, category: task.category, startTime: date,
                    isCompleted: false, notes: task.notes,
                    seriesID: series.id, originalScheduledDate: date
                )
                occurrence.reminderOffsets = offsets
                context.insert(occurrence)
            }
            try context.save()
            return series
        } catch {
            context.rollback()
            throw error
        }
    }
}
