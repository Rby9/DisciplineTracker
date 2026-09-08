import Foundation
import SwiftData
import UserNotifications
import Combine
import UIKit

@MainActor
final class NotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()
    @Published private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined
    @Published private(set) var lastError: String?
    @Published private(set) var deferredCount = 0
    @Published private(set) var scheduledThrough: Date?
    @Published var openTaskID: UUID?

    private var modelContext: ModelContext?
    private var excludedTaskIDs: Set<UUID> = []
    private var queuedPlan: Plan?
    private var worker: Task<Void, Never>?
    private let center = UNUserNotificationCenter.current()
    // Reserve one slot for the explicit test notification.
    private let taskLimit = 63
    private let categoryID = "dt.activity"
    private let completeAction = "dt.complete"
    private let snoozeAction = "dt.snooze"
    private let testID = "dt.test"

    private struct Event {
        let date: Date
        let request: UNNotificationRequest
    }
    private struct Plan {
        let events: [Event]
        let activeIDs: Set<UUID>
        let enabled: Bool
    }

    private override init() { super.init() }

    var isAuthorized: Bool {
        authorizationStatus == .authorized || authorizationStatus == .provisional || authorizationStatus == .ephemeral
    }

    var permissionLabel: String {
        switch authorizationStatus {
        case .notDetermined: return String(localized: "Not requested")
        case .denied: return String(localized: "Disabled in Settings")
        case .provisional: return String(localized: "Quiet delivery")
        case .authorized, .ephemeral: return String(localized: "Allowed")
        @unknown default: return String(localized: "Unknown")
        }
    }

    func configure(with context: ModelContext) {
        modelContext = context
        center.delegate = self
        let complete = UNNotificationAction(
            identifier: completeAction, title: String(localized: "Complete activity"),
            options: [.authenticationRequired]
        )
        let snooze = UNNotificationAction(
            identifier: snoozeAction, title: String(localized: "Remind me in 10 minutes"), options: []
        )
        center.setNotificationCategories([
            UNNotificationCategory(identifier: categoryID, actions: [complete, snooze], intentIdentifiers: [])
        ])
    }

    func updateAuthorizationStatus() async {
        authorizationStatus = await center.notificationSettings().authorizationStatus
    }

    func requestPermission() {
        Task {
            do {
                _ = try await center.requestAuthorization(options: [.alert, .sound, .badge])
                await updateAuthorizationStatus()
                refreshNotifications()
            } catch {
                lastError = String(localized: "Could not request notification permission.") + " " + error.localizedDescription
            }
        }
    }

    func clearError() { lastError = nil }

    func openSettings() {
        guard let url = URL(string: UIApplication.openNotificationSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    func scheduleNotifications(for task: TaskItem) {
        excludedTaskIDs.remove(task.id)
        refreshNotifications()
    }

    func cancelNotifications(for task: TaskItem) {
        excludedTaskIDs.insert(task.id)
        refreshNotifications()
    }

    func refreshNotifications() {
        guard let modelContext else { return }
        do {
            let tasks = try modelContext.fetch(FetchDescriptor<TaskItem>())
            excludedTaskIDs.formIntersection(Set(tasks.map(\.id)))
            let enabled = ReminderPreferences.enabled
            let now = Date()
            let active = tasks.filter { $0.isPending && !excludedTaskIDs.contains($0.id) }
            var events: [Event] = []
            if enabled {
                for task in active {
                    for offset in task.effectiveReminderOffsets {
                        let date = ReminderPolicy.fireDate(start: task.startTime, offset: offset)
                        guard date > now else { continue }
                        events.append(makeEvent(task: task, suffix: "offset.\(offset)", date: date))
                    }
                    if let date = task.snoozedUntil, date > now,
                       task.snoozedStartTime == task.startTime {
                        events.append(makeEvent(task: task, suffix: "snooze", date: date))
                    }
                }
            }
            // A snooze can coincide with a normal reminder: deliver only one alert.
            var seenInstants: Set<String> = []
            events = events.filter { event in
                let owner = event.request.content.threadIdentifier
                let second = Int64(event.date.timeIntervalSince1970.rounded(.down))
                return seenInstants.insert("\(owner):\(second)").inserted
            }
            events.sort {
                $0.date == $1.date ? $0.request.identifier < $1.request.identifier : $0.date < $1.date
            }
            queuedPlan = Plan(events: events, activeIDs: Set(active.map(\.id)), enabled: enabled)
            if worker == nil {
                worker = Task { await processQueue() }
            }
        } catch {
            lastError = String(localized: "Could not load activities for notifications.") + " " + error.localizedDescription
        }
    }

    private func makeEvent(task: TaskItem, suffix: String, date: Date) -> Event {
        let content = UNMutableNotificationContent()
        content.title = task.title
        let minutes = Int(task.startTime.timeIntervalSince(date) / 60)
        if minutes > 0 {
            content.body = String(format: String(localized: "Starts in %lld minutes."), Int64(minutes))
        } else if minutes == 0 {
            content.body = String(localized: "It's time to start.")
        } else {
            content.body = String(localized: "This activity is still pending.")
        }
        content.sound = .default
        content.categoryIdentifier = categoryID
        content.threadIdentifier = task.id.uuidString
        content.userInfo = ["taskID": task.id.uuidString]
        // Absolute instants: changing time zone preserves the saved task's actual start time.
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        components.timeZone = calendar.timeZone
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: "dt.\(task.id.uuidString).\(suffix)", content: content, trigger: trigger
        )
        return Event(date: date, request: request)
    }

    private func processQueue() async {
        defer { worker = nil }
        while let plan = queuedPlan {
            queuedPlan = nil
            await updateAuthorizationStatus()
            let pending = await center.pendingNotificationRequests()
            let delivered = await center.deliveredNotifications()
            if queuedPlan != nil { continue }

            lastError = nil
            let enabled = plan.enabled && isAuthorized
            let managed = pending.filter { isManaged($0.identifier) }
            let otherCount = pending.count - managed.count
            let capacity = max(0, taskLimit - otherCount)
            let future = plan.events.filter { $0.date > Date() }
            let selected = enabled ? Array(future.prefix(capacity)) : []
            let desiredIDs = Set(selected.map { $0.request.identifier })
            let obsolete = managed.filter { !desiredIDs.contains($0.identifier) }
            center.removePendingNotificationRequests(withIdentifiers: obsolete.map(\.identifier))
            if !plan.enabled {
                center.removePendingNotificationRequests(withIdentifiers: [testID])
                center.removeDeliveredNotifications(withIdentifiers: [testID])
            }
            let obsoleteDelivered = delivered.filter { notification in
                guard isManaged(notification.request.identifier) else { return false }
                guard enabled, let id = taskID(from: notification.request) else { return true }
                return !plan.activeIDs.contains(id)
            }
            center.removeDeliveredNotifications(withIdentifiers: obsoleteDelivered.map { $0.request.identifier })
            let old = Dictionary(uniqueKeysWithValues: managed.map { ($0.identifier, $0) })
            var scheduled: [Date] = []
            for event in selected {
                if queuedPlan != nil { break }
                guard event.date > Date() else { continue }
                if let existing = old[event.request.identifier], equivalent(existing, event.request) {
                    scheduled.append(event.date)
                    continue
                }
                do {
                    try await center.add(event.request)
                    scheduled.append(event.date)
                } catch {
                    lastError = String(localized: "Some reminders could not be scheduled.") + " " + error.localizedDescription
                }
            }
            if queuedPlan == nil {
                deferredCount = enabled ? max(0, future.count - scheduled.count) : 0
                scheduledThrough = scheduled.max()
            }
        }
    }

    private func equivalent(_ lhs: UNNotificationRequest, _ rhs: UNNotificationRequest) -> Bool {
        lhs.content.title == rhs.content.title && lhs.content.body == rhs.content.body &&
        lhs.content.categoryIdentifier == rhs.content.categoryIdentifier &&
        (lhs.trigger as? UNCalendarNotificationTrigger)?.dateComponents ==
            (rhs.trigger as? UNCalendarNotificationTrigger)?.dateComponents
    }

    private func isManaged(_ identifier: String) -> Bool {
        if identifier.hasPrefix("dt."), identifier != testID { return true }
        return legacyTaskID(identifier) != nil
    }

    private func legacyTaskID(_ identifier: String) -> UUID? {
        for suffix in ["-reminder", "-exact", "-overdue"] where identifier.hasSuffix(suffix) {
            return UUID(uuidString: String(identifier.dropLast(suffix.count)))
        }
        return nil
    }

    private func taskID(from request: UNNotificationRequest) -> UUID? {
        if let raw = request.content.userInfo["taskID"] as? String { return UUID(uuidString: raw) }
        return legacyTaskID(request.identifier)
    }

    func scheduleTest() async throws {
        guard ReminderPreferences.enabled else { throw ReminderError.paused }
        _ = try await center.requestAuthorization(options: [.alert, .sound, .badge])
        await updateAuthorizationStatus()
        guard isAuthorized else { throw ReminderError.permission }
        // Drain regular scheduling first, so the reserved slot remains available.
        refreshNotifications()
        await worker?.value
        guard ReminderPreferences.enabled else { throw ReminderError.paused }
        let content = UNMutableNotificationContent()
        content.title = String(localized: "Test notification")
        content.body = String(localized: "Your reminders are ready.")
        content.sound = .default
        try await center.add(UNNotificationRequest(
            identifier: testID, content: content,
            trigger: UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
        ))
        // A pause may arrive while the system accepts the request.
        if !ReminderPreferences.enabled {
            center.removePendingNotificationRequests(withIdentifiers: [testID])
            throw ReminderError.paused
        }
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter, willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .list, .sound])
        Task { @MainActor in self.refreshNotifications() }
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let rawID = response.notification.request.content.userInfo["taskID"] as? String
        let identifier = response.notification.request.identifier
        let action = response.actionIdentifier
        Task { @MainActor in
            let id = rawID.flatMap(UUID.init(uuidString:)) ?? self.legacyTaskID(identifier)
            if let id { await self.handle(action: action, taskID: id) }
            completionHandler()
        }
    }

    private func handle(action: String, taskID: UUID) async {
        guard let context = modelContext else { return }
        do {
            let descriptor = FetchDescriptor<TaskItem>(predicate: #Predicate { $0.id == taskID })
            guard let task = try context.fetch(descriptor).first else {
                refreshNotifications()
                await worker?.value
                return
            }
            switch action {
            case UNNotificationDefaultActionIdentifier:
                openTaskID = task.id
            case completeAction:
                try context.save()
                try TaskStatusStore.set(.completed, for: task, in: context)
            case snoozeAction:
                guard task.isPending, ReminderPreferences.enabled else { break }
                try context.save()
                let previous = task.snoozedUntil
                let previousStart = task.snoozedStartTime
                task.snoozedUntil = Date().addingTimeInterval(600)
                task.snoozedStartTime = task.startTime
                do { try context.save() }
                catch {
                    task.snoozedUntil = previous
                    task.snoozedStartTime = previousStart
                    throw error
                }
            default: break
            }
            refreshNotifications()
            await worker?.value
        } catch {
            lastError = String(localized: "The notification action could not be saved.") + " " + error.localizedDescription
            openTaskID = taskID
        }
    }

    private enum ReminderError: LocalizedError {
        case paused, permission
        var errorDescription: String? {
            switch self {
            case .paused: return String(localized: "Enable notifications in Profile first.")
            case .permission: return String(localized: "Allow notifications in iPhone Settings first.")
            }
        }
    }
}
