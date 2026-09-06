import Foundation

/// Calendar days, not fixed 24-hour intervals: keeps the local hour across DST.
enum RecurrenceSchedule {
    enum ScheduleError: LocalizedError {
        case invalidRange, noWeekdays, tooLong, invalidDate

        var errorDescription: String? {
            switch self {
            case .invalidRange: return "The end date must be on or after the first day."
            case .noWeekdays: return "Select at least one weekday."
            case .tooLong: return "Choose a period shorter than 10 years."
            case .invalidDate: return "The selected date or time could not be calculated."
            }
        }
    }

    static func dates(
        from start: Date, through end: Date,
        hour: Int, minute: Int, weekdays: Set<Int>,
        after cutoff: Date? = nil, excludingDay: Date? = nil,
        calendar: Calendar = .current
    ) throws -> [Date] {
        guard !weekdays.isEmpty, weekdays.isSubset(of: Set(1...7)) else {
            throw ScheduleError.noWeekdays
        }
        guard (0...23).contains(hour), (0...59).contains(minute) else {
            throw ScheduleError.invalidDate
        }
        let first = calendar.startOfDay(for: start)
        let last = calendar.startOfDay(for: end)
        guard last >= first else { throw ScheduleError.invalidRange }
        guard let span = calendar.dateComponents([.day], from: first, to: last).day else {
            throw ScheduleError.invalidDate
        }
        guard span < 3650 else { throw ScheduleError.tooLong }
        return try (0...span).compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: offset, to: first) else {
                throw ScheduleError.invalidDate
            }
            guard weekdays.contains(calendar.component(.weekday, from: day)) else { return nil }
            if let excludingDay, calendar.isDate(day, inSameDayAs: excludingDay) { return nil }
            // On a spring clock change, use the next valid time on that day.
            // On a repeated autumn hour, use the first occurrence only.
            guard let date = calendar.date(bySettingHour: hour, minute: minute, second: 0,
                                           of: day, matchingPolicy: .nextTime,
                                           repeatedTimePolicy: .first, direction: .forward),
                  calendar.isDate(date, inSameDayAs: day) else {
                throw ScheduleError.invalidDate
            }
            if let cutoff, date <= cutoff { return nil }
            return date
        }
    }

    static func lastDay(starting start: Date, months: Int, calendar: Calendar = .current) -> Date {
        let first = calendar.startOfDay(for: start)
        guard let anniversary = calendar.date(byAdding: .month, value: months, to: first),
              let last = calendar.date(byAdding: .day, value: -1, to: anniversary) else { return first }
        return last
    }
}
