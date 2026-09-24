import Foundation

struct RoutineStreakSummary: Equatable {
    let current: Int
    let longest: Int
    let completedOccurrences: Int
    let dueOccurrences: Int

    static let empty = RoutineStreakSummary(
        current: 0,
        longest: 0,
        completedOccurrences: 0,
        dueOccurrences: 0
    )
}

enum RoutineStreakCalculator {
    static func summary(
        for routine: TaskSeries,
        tasks: [TaskItem],
        now: Date = .now,
        calendar: Calendar = .current
    ) -> RoutineStreakSummary {
        guard let scheduledDates = try? RecurrenceSchedule.dates(
            from: routine.startDate,
            through: routine.endDate,
            hour: routine.hour,
            minute: routine.minute,
            weekdays: Set(routine.weekdays),
            calendar: calendar
        ) else {
            return .empty
        }

        let excludedKeys = Set(routine.excludedDayKeys ?? [])
        let dueDates = scheduledDates.filter {
            $0 <= now && !excludedKeys.contains(JournalEntry.key(for: $0))
        }
        let completedKeys = Set(
            tasks.lazy
                .filter { $0.seriesID == routine.id && $0.isCompleted }
                .map { JournalEntry.key(for: $0.originalScheduledDate ?? $0.startTime) }
        )

        var current = 0
        var longest = 0
        var completed = 0

        for date in dueDates {
            if completedKeys.contains(JournalEntry.key(for: date)) {
                completed += 1
                current += 1
                longest = max(longest, current)
            } else {
                current = 0
            }
        }

        return RoutineStreakSummary(
            current: current,
            longest: longest,
            completedOccurrences: completed,
            dueOccurrences: dueDates.count
        )
    }
}
