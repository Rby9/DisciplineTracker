import Foundation
import SwiftData

@MainActor
enum BackupChecks {
    static func run(in source: ModelContext) throws {
        let backup = try BackupStore.capture(in: source)
        let bytes = try BackupStore.encode(backup)
        let decoded = try BackupStore.decode(bytes)
        try Checks.expect(decoded.tasks.count == backup.tasks.count, "Backup round trip retains task count")
        try Checks.expect(decoded.routines.count == backup.routines.count, "Backup round trip retains routines")
        try Checks.expect(decoded.journal.count == backup.journal.count, "Backup round trip retains journal")
        let destination = try ModelContainer(for: TaskItem.self, TaskSeries.self, JournalEntry.self,
                                            configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = destination.mainContext
        let first = try BackupStore.restore(decoded, in: context)
        try Checks.expect(first.total == decoded.tasks.count + decoded.routines.count + decoded.journal.count,
                          "Empty-store restoration adds every record")
        let restored = try context.fetch(FetchDescriptor<TaskItem>())
        for task in restored {
            let original = decoded.tasks.first { $0.id == task.id }!
            try Checks.expect(task.title == original.title && task.notes == original.notes, "Task text survives backup")
            try Checks.expect(task.reminderOffsets == original.reminderOffsets, "nil versus disabled versus custom reminders survive")
            try Checks.expect(task.seriesID == original.seriesID && task.skipped == original.skipped,
                              "Routine link and skipped state survive")
            try Checks.expect(abs(task.startTime.timeIntervalSince(original.startTime)) < 0.001, "Date instant survives")
        }
        let journals = try context.fetch(FetchDescriptor<JournalEntry>())
        try Checks.expect(Set(journals.map(\.dayKey)) == Set(decoded.journal.map(\.dayKey)), "Journal identities survive")
        if let task = restored.first { task.title = "Keep my newer edit" }
        try context.save()
        let second = try BackupStore.restore(decoded, in: context)
        try Checks.expect(second.total == 0, "Import is idempotent")
        try Checks.expect(restored.first?.title == "Keep my newer edit", "Restore preserves newer local edits")
        let before = restored.count
        var invalid = decoded
        invalid.version = 999
        do {
            _ = try BackupStore.restore(invalid, in: context)
            throw Checks.CheckError(message: "Future schema accepted")
        } catch BackupStore.BackupError.unsupported {}
        invalid = decoded
        if let task = invalid.tasks.first { invalid.tasks.append(task) }
        do {
            _ = try BackupStore.restore(invalid, in: context)
            throw Checks.CheckError(message: "Duplicate IDs accepted")
        } catch BackupStore.BackupError.invalid {}
        do {
            _ = try BackupStore.decode(Data(bytes.prefix(bytes.count / 2)))
            throw Checks.CheckError(message: "Truncated backup accepted")
        } catch BackupStore.BackupError.invalid {}
        let after = try context.fetch(FetchDescriptor<TaskItem>()).count
        try Checks.expect(before == after, "Invalid imports leave data untouched")
        print("PASS: backup round trip, empty restore, identities, conflict preservation, repeat import, invalid input")
    }
}
