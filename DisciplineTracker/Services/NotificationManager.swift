import Foundation
import SwiftData
import UserNotifications

@MainActor
final class NotificationManager: NSObject, UNUserNotificationCenterDelegate {

    // MARK: - Singleton

    static let shared = NotificationManager()

    private override init() {
        super.init()
    }

    // MARK: - Properties

    private var modelContext: ModelContext?
    private var excludedTaskIDs: Set<UUID> = []

    private var queuedRequests: [UNNotificationRequest]?
    private var isProcessingQueue = false

    private let notificationLimit = 64

    // MARK: - Configuration

    func configure(with context: ModelContext) {
        modelContext = context
        UNUserNotificationCenter.current().delegate = self
    }

    // MARK: - Permission

    func requestPermission() {
        Task {
            do {
                let granted = try await UNUserNotificationCenter
                    .current()
                    .requestAuthorization(
                        options: [.alert, .sound, .badge]
                    )

                if granted {
                    refreshNotifications()
                }
            } catch {
                print(
                    "Notification permission error: \(error.localizedDescription)"
                )
            }
        }
    }

    // MARK: - Existing Task Actions

    func scheduleNotifications(for task: TaskItem) {
        excludedTaskIDs.remove(task.id)
        if !task.isPending {
            UNUserNotificationCenter.current().removePendingNotificationRequests(
                withIdentifiers: identifiers(for: task.id)
            )
        }
        refreshNotifications()
    }

    func cancelNotifications(for task: TaskItem) {
        excludedTaskIDs.insert(task.id)

        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(
                withIdentifiers: identifiers(for: task.id)
            )

        refreshNotifications()
    }

    // MARK: - Refresh

    func refreshNotifications() {
        guard let modelContext else {
            return
        }

        do {
            let descriptor = FetchDescriptor<TaskItem>()
            let tasks = try modelContext.fetch(descriptor)

            let existingIDs = Set(tasks.map(\.id))
            excludedTaskIDs.formIntersection(existingIDs)

            let now = Date()

            var events: [
                (date: Date, request: UNNotificationRequest)
            ] = []

            for task in tasks {
                guard task.isPending,
                      !excludedTaskIDs.contains(task.id) else {
                    continue
                }

                let reminderDate = Calendar.current.date(
                    byAdding: .minute,
                    value: -10,
                    to: task.startTime
                ) ?? task.startTime

                let overdueDate = Calendar.current.date(
                    byAdding: .minute,
                    value: 15,
                    to: task.startTime
                ) ?? task.startTime

                if reminderDate > now {
                    events.append((
                        date: reminderDate,
                        request: makeRequest(
                            taskID: task.id,
                            suffix: "reminder",
                            title: "Reminder",
                            body: "\(task.title) in 10 minutes",
                            date: reminderDate
                        )
                    ))
                }

                if task.startTime > now {
                    events.append((
                        date: task.startTime,
                        request: makeRequest(
                            taskID: task.id,
                            suffix: "exact",
                            title: "Time for: \(task.title)",
                            body: "It's time!",
                            date: task.startTime
                        )
                    ))
                }

                if overdueDate > now {
                    events.append((
                        date: overdueDate,
                        request: makeRequest(
                            taskID: task.id,
                            suffix: "overdue",
                            title: "Overdue",
                            body: "You still haven't completed: \(task.title)",
                            date: overdueDate
                        )
                    ))
                }
            }

            events.sort {
                if $0.date == $1.date {
                    return $0.request.identifier < $1.request.identifier
                }

                return $0.date < $1.date
            }

            queuedRequests = events
                .prefix(notificationLimit)
                .map { $0.request }

            startQueueIfNeeded()

        } catch {
            print(
                "Could not load tasks for notifications: \(error.localizedDescription)"
            )
        }
    }

    // MARK: - Request Creation

    private func makeRequest(
        taskID: UUID,
        suffix: String,
        title: String,
        body: String,
        date: Date
    ) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: date
        )

        let trigger = UNCalendarNotificationTrigger(
            dateMatching: components,
            repeats: false
        )

        return UNNotificationRequest(
            identifier: "\(taskID)-\(suffix)",
            content: content,
            trigger: trigger
        )
    }

    // MARK: - Serial Scheduling

    private func startQueueIfNeeded() {
        guard !isProcessingQueue else {
            return
        }

        isProcessingQueue = true

        Task {
            await processQueue()
        }
    }

    private func processQueue() async {
        let center = UNUserNotificationCenter.current()

        while let requests = queuedRequests {
            queuedRequests = nil

            let pending = await center.pendingNotificationRequests()
            // A newer task state arrived while awaiting the system.
            if queuedRequests != nil { continue }

            let managed = pending.filter {
                isTaskNotification($0.identifier)
            }

            let otherCount = pending.count - managed.count
            let availableSlots = max(
                0,
                notificationLimit - otherCount
            )

            center.removePendingNotificationRequests(
                withIdentifiers: managed.map(\.identifier)
            )

            for request in requests.prefix(availableSlots) {
                if queuedRequests != nil { break }
                guard let trigger = request.trigger
                    as? UNCalendarNotificationTrigger,
                      let nextDate = trigger.nextTriggerDate(),
                      nextDate > Date() else {
                    continue
                }

                do {
                    try await center.add(request)
                } catch {
                    print(
                        "Notification scheduling error: \(error.localizedDescription)"
                    )
                }
            }
        }

        isProcessingQueue = false
    }

    // Show reminders while the app is open as well as on the lock screen.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    // MARK: - Helpers

    private func identifiers(for taskID: UUID) -> [String] {
        [
            "\(taskID)-reminder",
            "\(taskID)-exact",
            "\(taskID)-overdue"
        ]
    }

    private func isTaskNotification(_ identifier: String) -> Bool {
        for suffix in ["-reminder", "-exact", "-overdue"] {
            guard identifier.hasSuffix(suffix) else {
                continue
            }

            let prefix = String(
                identifier.dropLast(suffix.count)
            )

            if UUID(uuidString: prefix) != nil {
                return true
            }
        }

        return false
    }
}
