import ActivityKit
import Foundation
import SwiftData

nonisolated struct RitvaraActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        let dailyCompleted: Int
        let dailyTotal: Int
    }

    let taskID: UUID
    let title: String
    let startTime: Date
    let categoryName: String
    let categoryColorHex: String
}

enum LiveActivityPreferences {
    static let enabledKey = "liveActivities.enabled"
    static let leadMinutesKey = "liveActivities.leadMinutes"

    static var isEnabled: Bool {
        (UserDefaults.standard.object(forKey: enabledKey) as? Bool) ?? true
    }

    static var leadMinutes: Int {
        let stored = UserDefaults.standard.object(forKey: leadMinutesKey) as? Int
        return min(max(stored ?? 30, 5), 120)
    }

    static let postStartLifetime: TimeInterval = 15 * 60
}

@MainActor
enum RitvaraLiveActivityManager {
    static func synchronize(context: ModelContext) async {
        let descriptor = FetchDescriptor<TaskItem>(
            sortBy: [SortDescriptor(\TaskItem.startTime)]
        )
        let tasks = (try? context.fetch(descriptor)) ?? []
        await synchronize(tasks: tasks)
    }

    static func synchronize(tasks: [TaskItem], now: Date = .now) async {
        guard LiveActivityPreferences.isEnabled,
              ActivityAuthorizationInfo().areActivitiesEnabled else {
            await endAll()
            return
        }

        let calendar = Calendar.current
        let pending = tasks.filter { $0.isPending }.sorted { $0.startTime < $1.startTime }
        let currentTask = pending.last {
            calendar.isDate($0.startTime, inSameDayAs: now)
                && $0.startTime <= now
                && now < expirationDate(for: $0)
        }
        let candidate = currentTask ?? pending.first(where: { $0.startTime > now })

        guard let candidate else {
            await endAll()
            return
        }

        let candidateDayTasks = tasks.filter {
            calendar.isDate($0.startTime, inSameDayAs: candidate.startTime) && !$0.isSkipped
        }

        let state = RitvaraActivityAttributes.ContentState(
            dailyCompleted: candidateDayTasks.filter(\.isCompleted).count,
            dailyTotal: candidateDayTasks.count
        )
        let existing = Activity<RitvaraActivityAttributes>.activities
        let matching = existing.first {
            $0.attributes.taskID == candidate.id && isReusable($0.activityState)
        }

        for activity in existing
        where activity.id != matching?.id && isReusable(activity.activityState) {
            await activity.end(
                ActivityContent(state: activity.content.state, staleDate: nil),
                dismissalPolicy: .immediate
            )
        }

        if let matching,
           matching.attributes.title == candidate.title,
           matching.attributes.startTime == candidate.startTime,
           matching.attributes.categoryName == candidate.category.rawValue,
           matching.attributes.categoryColorHex == categoryColorHex(for: candidate.category) {
            await matching.update(
                ActivityContent(
                    state: state,
                    staleDate: expirationDate(for: candidate)
                )
            )
            return
        }

        if let matching {
            await matching.end(
                ActivityContent(state: matching.content.state, staleDate: nil),
                dismissalPolicy: .immediate
            )
        }

        requestActivity(for: candidate, state: state, now: now)
    }

    static func end(for taskID: UUID) async {
        for activity in Activity<RitvaraActivityAttributes>.activities
        where activity.attributes.taskID == taskID {
            await activity.end(
                ActivityContent(state: activity.content.state, staleDate: nil),
                dismissalPolicy: .immediate
            )
        }
    }

    private static func requestActivity(
        for task: TaskItem,
        state: RitvaraActivityAttributes.ContentState,
        now: Date
    ) {
        let attributes = RitvaraActivityAttributes(
            taskID: task.id,
            title: task.title,
            startTime: task.startTime,
            categoryName: task.category.rawValue,
            categoryColorHex: categoryColorHex(for: task.category)
        )
        let content = ActivityContent(
            state: state,
            staleDate: expirationDate(for: task)
        )
        let activationDate = task.startTime.addingTimeInterval(
            -Double(LiveActivityPreferences.leadMinutes) * 60
        )

        do {
            if #available(iOS 26.0, *), activationDate > now {
                let alert = AlertConfiguration(
                    title: "Upcoming activity",
                    body: "Your activity starts soon.",
                    sound: .default
                )
                let activity = try Activity.request(
                    attributes: attributes,
                    content: content,
                    style: .standard,
                    alertConfiguration: alert,
                    start: activationDate
                )
                print("Scheduled Live Activity \(activity.id) for \(activationDate)")
                scheduleExpiration(
                    of: activity,
                    state: state,
                    at: expirationDate(for: task)
                )
            } else if activationDate <= now {
                let activity = try Activity.request(
                    attributes: attributes,
                    content: content,
                    pushType: nil
                )
                print("Started Live Activity \(activity.id)")
                scheduleExpiration(
                    of: activity,
                    state: state,
                    at: expirationDate(for: task)
                )
            }
        } catch {
            print("Live Activity could not be started: \(error.localizedDescription)")
        }
    }

    private static func endAll() async {
        for activity in Activity<RitvaraActivityAttributes>.activities
        where isReusable(activity.activityState) {
            await activity.end(
                ActivityContent(state: activity.content.state, staleDate: nil),
                dismissalPolicy: .immediate
            )
        }
    }

    private static func isReusable(_ state: ActivityState) -> Bool {
        switch state {
        case .active, .pending, .stale:
            true
        case .ended, .dismissed:
            false
        @unknown default:
            false
        }
    }

    private static func categoryColorHex(for category: TaskCategory) -> String {
        switch category {
        case .gym: "FF453A"
        case .food: "FF9F0A"
        case .work: "0A84FF"
        case .sleep: "BF5AF2"
        case .medication: "64D2FF"
        case .study: "5E5CE6"
        case .personal: "FF375F"
        case .household: "30D158"
        case .other: "8E8E93"
        }
    }

    private static func expirationDate(for task: TaskItem) -> Date {
        task.startTime.addingTimeInterval(LiveActivityPreferences.postStartLifetime)
    }

    private static func scheduleExpiration(
        of activity: Activity<RitvaraActivityAttributes>,
        state: RitvaraActivityAttributes.ContentState,
        at date: Date
    ) {
        let delay = max(date.timeIntervalSinceNow, 0)
        Task {
            do {
                try await Task.sleep(for: .seconds(delay))
            } catch {
                return
            }

            await activity.end(
                ActivityContent(state: state, staleDate: date),
                dismissalPolicy: .immediate
            )
        }
    }
}
