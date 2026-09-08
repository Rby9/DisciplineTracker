import SwiftData

@MainActor
enum TaskStatusStore {
    static func set(_ status: TaskStatus, for task: TaskItem, in context: ModelContext) throws {
        let previous = task.status
        let oldSnooze = task.snoozedUntil
        let oldSnoozeStart = task.snoozedStartTime
        task.setStatus(status)
        do {
            try context.save()
        } catch {
            task.setStatus(previous)
            task.snoozedUntil = oldSnooze
            task.snoozedStartTime = oldSnoozeStart
            throw error
        }
        NotificationManager.shared.scheduleNotifications(for: task)
    }
}
