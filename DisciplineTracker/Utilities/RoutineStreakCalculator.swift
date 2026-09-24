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

enum RoutineOccurrenceState: Equatable {
    case completed
    case missed
    case paused
    case upcoming
}

struct RoutineOccurrence: Identifiable, Equatable {
    let date: Date
    let state: RoutineOccurrenceState

    var id: Date { date }
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
            intervalDays: routine.repeatIntervalDays,
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

    static func history(
        for routine: TaskSeries,
        tasks: [TaskItem],
        limit: Int = 28,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> [RoutineOccurrence] {
        let lastDay = min(routine.endDate, now)
        guard limit > 0,
              let dates = try? RecurrenceSchedule.dates(
                from: routine.startDate,
                through: lastDay,
                hour: routine.hour,
                minute: routine.minute,
                weekdays: Set(routine.weekdays),
                intervalDays: routine.repeatIntervalDays,
                calendar: calendar
              ) else {
            return []
        }

        let excludedKeys = Set(routine.excludedDayKeys ?? [])
        let routineTasks = tasks.filter { $0.seriesID == routine.id }
        let tasksByKey = Dictionary(
            routineTasks.map {
                (
                    JournalEntry.key(for: $0.originalScheduledDate ?? $0.startTime),
                    $0
                )
            },
            uniquingKeysWith: { first, _ in first }
        )

        return dates.suffix(limit).map { date in
            let key = JournalEntry.key(for: date)
            let state: RoutineOccurrenceState

            if excludedKeys.contains(key) {
                state = .paused
            } else if date > now {
                state = .upcoming
            } else if tasksByKey[key]?.isCompleted == true {
                state = .completed
            } else {
                state = .missed
            }

            return RoutineOccurrence(date: date, state: state)
        }
    }
}
