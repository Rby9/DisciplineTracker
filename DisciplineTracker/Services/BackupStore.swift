import Foundation
import SwiftData

struct TrackerBackup: Codable {
    var format = "DisciplineTrackerBackup"
    var version = 1
    var createdAt = Date()
    var tasks: [BackupTask]
    var routines: [BackupRoutine]
    var journal: [BackupJournal]
    var goals: [BackupGoal]?
    var preferences: BackupPreferences
}

struct BackupTask: Codable {
    var id: UUID
    var title: String
    var category: TaskCategory
    var startTime: Date
    var isCompleted: Bool
    var skipped: Bool?
    var notes: String
    var seriesID: UUID?
    var originalScheduledDate: Date?
    var reminderOffsets: [Int]?
    var reminderOverride: Bool?
    var snoozedUntil: Date?
    var snoozedStartTime: Date?
}

struct BackupRoutine: Codable {
    var id: UUID
    var title: String
    var category: TaskCategory
    var notes: String
    var startDate: Date
    var endDate: Date
    var hour: Int
    var minute: Int
    var weekdays: [Int]
    var excludedDayKeys: [String]?
    var reminderOffsets: [Int]?
}

struct BackupJournal: Codable {
    var dayKey: String
    var date: Date
    var note: String
    var moodRaw: String?
    var updatedAt: Date
}

struct BackupGoal: Codable {
    var id: UUID
    var title: String
    var periodRaw: String
    var categoryRaw: String?
    var targetCount: Int
    var startDate: Date
    var endDate: Date
    var createdAt: Date
}

struct BackupPreferences: Codable {
    var name: String
    var symbol: String
    var notificationsEnabled: Bool
    var defaultOffsets: [Int]
}

struct BackupPreview {
    var tasks: Int
    var routines: Int
    var journal: Int
    var goals: Int
    var skipped: Int
    var total: Int { tasks + routines + journal + goals }
}

@MainActor
enum BackupStore {
    static let maximumBytes = 20 * 1024 * 1024

    enum BackupError: LocalizedError {
        case invalid, tooLarge, unsupported
        var errorDescription: String? {
            switch self {
            case .invalid: return String(localized: "This backup is invalid or incomplete. Nothing was restored.")
            case .tooLarge: return String(localized: "This backup is too large. The limit is 20 MB or 50000 records.")
            case .unsupported: return String(localized: "This backup belongs to another app or a newer format.")
            }
        }
    }

    static func capture(in context: ModelContext) throws -> TrackerBackup {
        try context.save()
        let tasks = try context.fetch(FetchDescriptor<TaskItem>()).sorted { $0.id.uuidString < $1.id.uuidString }
        let routines = try context.fetch(FetchDescriptor<TaskSeries>()).sorted { $0.id.uuidString < $1.id.uuidString }
        let journal = try context.fetch(FetchDescriptor<JournalEntry>()).sorted { $0.dayKey < $1.dayKey }
        let goals = try context.fetch(FetchDescriptor<Goal>()).sorted { $0.id.uuidString < $1.id.uuidString }
        return TrackerBackup(
            tasks: tasks.map {
                BackupTask(id: $0.id, title: $0.title, category: $0.category, startTime: $0.startTime,
                           isCompleted: $0.isCompleted, skipped: $0.skipped, notes: $0.notes,
                           seriesID: $0.seriesID, originalScheduledDate: $0.originalScheduledDate,
                           reminderOffsets: $0.reminderOffsets, reminderOverride: $0.reminderOverride,
                           snoozedUntil: $0.snoozedUntil, snoozedStartTime: $0.snoozedStartTime)
            },
            routines: routines.map {
                BackupRoutine(id: $0.id, title: $0.title, category: $0.category, notes: $0.notes,
                              startDate: $0.startDate, endDate: $0.endDate, hour: $0.hour, minute: $0.minute,
                              weekdays: $0.weekdays, excludedDayKeys: $0.excludedDayKeys,
                              reminderOffsets: $0.reminderOffsets)
            },
            journal: journal.map {
                BackupJournal(dayKey: $0.dayKey, date: $0.date, note: $0.note, moodRaw: $0.moodRaw, updatedAt: $0.updatedAt)
            },
            goals: goals.map {
                BackupGoal(id: $0.id, title: $0.title, periodRaw: $0.periodRaw,
                           categoryRaw: $0.categoryRaw, targetCount: $0.targetCount,
                           startDate: $0.startDate, endDate: $0.endDate, createdAt: $0.createdAt)
            },
            preferences: BackupPreferences(name: UserDefaults.standard.string(forKey: "profile.name") ?? "",
                                           symbol: UserDefaults.standard.string(forKey: "profile.symbol") ?? "person.fill",
                                           notificationsEnabled: ReminderPreferences.enabled,
                                           defaultOffsets: ReminderPreferences.defaultOffsets)
        )
    }

    static func encode(_ backup: TrackerBackup) throws -> Data {
        try validate(backup)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        // Millisecond timestamps round-trip independently of locale and time zone.
        encoder.dateEncodingStrategy = .millisecondsSince1970
        let data = try encoder.encode(backup)
        guard data.count <= maximumBytes else { throw BackupError.tooLarge }
        return data
    }

    static func decode(_ data: Data) throws -> TrackerBackup {
        guard data.count <= maximumBytes else { throw BackupError.tooLarge }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        let backup: TrackerBackup
        do { backup = try decoder.decode(TrackerBackup.self, from: data) }
        catch { throw BackupError.invalid }
        try validate(backup)
        return backup
    }

    static func validate(_ backup: TrackerBackup) throws {
        guard backup.format == "DisciplineTrackerBackup", backup.version == 1 else { throw BackupError.unsupported }
        guard backup.tasks.count + backup.routines.count + backup.journal.count + (backup.goals?.count ?? 0) <= 50_000 else { throw BackupError.tooLarge }
        func validDate(_ date: Date) -> Bool {
            date.timeIntervalSince1970.isFinite && date >= Date.distantPast && date <= Date.distantFuture
        }
        func validOffsets(_ offsets: [Int]?) -> Bool {
            guard let offsets else { return true }
            return Set(offsets).count == offsets.count && offsets.allSatisfy { $0 == -15 || (0...ReminderPolicy.maximumMinutes).contains($0) }
        }
        guard validDate(backup.createdAt),
              Set(backup.tasks.map(\.id)).count == backup.tasks.count,
              Set(backup.routines.map(\.id)).count == backup.routines.count,
              Set(backup.journal.map(\.dayKey)).count == backup.journal.count,
              Set((backup.goals ?? []).map(\.id)).count == (backup.goals ?? []).count,
              validOffsets(backup.preferences.defaultOffsets),
              backup.preferences.defaultOffsets.allSatisfy({ $0 >= 0 }) else { throw BackupError.invalid }
        let seriesIDs = Set(backup.routines.map(\.id))
        for task in backup.tasks {
            guard validDate(task.startTime), validOffsets(task.reminderOffsets),
                  !(task.isCompleted && task.skipped == true),
                  task.seriesID.map({ seriesIDs.contains($0) }) ?? true,
                  [task.originalScheduledDate, task.snoozedUntil, task.snoozedStartTime].compactMap({ $0 }).allSatisfy(validDate)
            else { throw BackupError.invalid }
        }
        for routine in backup.routines {
            // Stopped routines can legitimately end before their original start date.
            guard validDate(routine.startDate), validDate(routine.endDate),
                  (0...23).contains(routine.hour), (0...59).contains(routine.minute),
                  !routine.weekdays.isEmpty, routine.weekdays.allSatisfy({ (1...7).contains($0) }),
                  Set(routine.weekdays).count == routine.weekdays.count,
                  validOffsets(routine.reminderOffsets) else { throw BackupError.invalid }
        }
        for entry in backup.journal {
            guard !entry.dayKey.isEmpty, validDate(entry.date), validDate(entry.updatedAt),
                  entry.moodRaw.map({ JournalMood(rawValue: $0) != nil }) ?? true else { throw BackupError.invalid }
        }
        for goal in backup.goals ?? [] {
            guard !goal.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  GoalPeriod(rawValue: goal.periodRaw) != nil,
                  goal.categoryRaw.map({ TaskCategory(rawValue: $0) != nil }) ?? true,
                  (1...500).contains(goal.targetCount), validDate(goal.startDate),
                  validDate(goal.endDate), goal.endDate > goal.startDate,
                  validDate(goal.createdAt) else { throw BackupError.invalid }
        }
    }

    static func preview(_ backup: TrackerBackup, in context: ModelContext) throws -> BackupPreview {
        try validate(backup)
        let tasks = Set(try context.fetch(FetchDescriptor<TaskItem>()).map(\.id))
        let routines = Set(try context.fetch(FetchDescriptor<TaskSeries>()).map(\.id))
        let journal = Set(try context.fetch(FetchDescriptor<JournalEntry>()).map(\.dayKey))
        let goals = Set(try context.fetch(FetchDescriptor<Goal>()).map(\.id))
        let newTasks = backup.tasks.filter { !tasks.contains($0.id) }.count
        let newRoutines = backup.routines.filter { !routines.contains($0.id) }.count
        let newEntries = backup.journal.filter { !journal.contains($0.dayKey) }.count
        let newGoals = (backup.goals ?? []).filter { !goals.contains($0.id) }.count
        return BackupPreview(tasks: newTasks, routines: newRoutines, journal: newEntries, goals: newGoals,
                             skipped: backup.tasks.count + backup.routines.count + backup.journal.count + (backup.goals?.count ?? 0) - newTasks - newRoutines - newEntries - newGoals)
    }

    /// Add missing identities only. Existing content always wins on conflicts.
    @discardableResult
    static func restore(_ backup: TrackerBackup, in context: ModelContext) throws -> BackupPreview {
        try validate(backup)
        try context.save()
        let result = try preview(backup, in: context)
        let taskIDs = Set(try context.fetch(FetchDescriptor<TaskItem>()).map(\.id))
        let seriesIDs = Set(try context.fetch(FetchDescriptor<TaskSeries>()).map(\.id))
        let dayKeys = Set(try context.fetch(FetchDescriptor<JournalEntry>()).map(\.dayKey))
        let goalIDs = Set(try context.fetch(FetchDescriptor<Goal>()).map(\.id))
        do {
            for source in backup.routines where !seriesIDs.contains(source.id) {
                let routine = TaskSeries(id: source.id, title: source.title, category: source.category, notes: source.notes,
                                         startDate: source.startDate, endDate: source.endDate,
                                         hour: source.hour, minute: source.minute, weekdays: source.weekdays)
                routine.excludedDayKeys = source.excludedDayKeys
                routine.reminderOffsets = source.reminderOffsets
                context.insert(routine)
            }
            for source in backup.tasks where !taskIDs.contains(source.id) {
                let task = TaskItem(id: source.id, title: source.title, category: source.category, startTime: source.startTime,
                                    isCompleted: source.isCompleted, notes: source.notes, seriesID: source.seriesID,
                                    originalScheduledDate: source.originalScheduledDate)
                task.skipped = source.skipped
                task.reminderOffsets = source.reminderOffsets
                task.reminderOverride = source.reminderOverride
                task.snoozedUntil = source.snoozedUntil
                task.snoozedStartTime = source.snoozedStartTime
                context.insert(task)
            }
            for source in backup.journal where !dayKeys.contains(source.dayKey) {
                let entry = JournalEntry(date: source.date, note: source.note, moodRaw: source.moodRaw)
                entry.dayKey = source.dayKey
                entry.updatedAt = source.updatedAt
                context.insert(entry)
            }
            for source in backup.goals ?? [] where !goalIDs.contains(source.id) {
                guard let period = GoalPeriod(rawValue: source.periodRaw) else {
                    throw BackupError.invalid
                }
                let goal = Goal(id: source.id, title: source.title, period: period,
                                category: source.categoryRaw.flatMap(TaskCategory.init(rawValue:)),
                                targetCount: source.targetCount, startDate: source.startDate,
                                endDate: source.endDate, createdAt: source.createdAt)
                context.insert(goal)
            }
            try context.save()
            return result
        } catch {
            context.rollback()
            throw error
        }
    }

    static func restorePreferences(_ preferences: BackupPreferences) {
        UserDefaults.standard.set(preferences.name, forKey: "profile.name")
        UserDefaults.standard.set(preferences.symbol, forKey: "profile.symbol")
        UserDefaults.standard.set(preferences.notificationsEnabled, forKey: ReminderPreferences.enabledKey)
        ReminderPreferences.defaultOffsets = preferences.defaultOffsets
    }
}
