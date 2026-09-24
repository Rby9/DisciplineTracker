import ActivityKit
import Foundation

struct RitvaraActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        let dailyCompleted: Int
        let dailyTotal: Int
    }

    let taskID: UUID
    let title: String
    let startTime: Date
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
}

@MainActor
enum RitvaraLiveActivityManager {
    static func synchronize(tasks: [TaskItem], now: Date = .now) async {
        guard LiveActivityPreferences.isEnabled,
              ActivityAuthorizationInfo().areActivitiesEnabled else {
            await endAll()
            return
        }

        let calendar = Calendar.current
        let todayTasks = tasks.filter {
            calendar.isDate($0.startTime, inSameDayAs: now) && !$0.isSkipped
        }
        let pending = todayTasks.filter(\.isPending).sorted { $0.startTime < $1.startTime }
        let candidate = pending.first(where: { $0.startTime >= now }) ?? pending.last

        guard let candidate else {
            await endAll()
            return
        }

        let state = RitvaraActivityAttributes.ContentState(
            dailyCompleted: todayTasks.filter(\.isCompleted).count,
            dailyTotal: todayTasks.count
        )
        let existing = Activity<RitvaraActivityAttributes>.activities
        let matching = existing.first { $0.attributes.taskID == candidate.id }

        for activity in existing where activity.id != matching?.id {
            await activity.end(
                ActivityContent(state: activity.content.state, staleDate: nil),
                dismissalPolicy: .immediate
            )
        }

        if let matching,
           matching.attributes.title == candidate.title,
           matching.attributes.startTime == candidate.startTime {
            await matching.update(ActivityContent(state: state, staleDate: nil))
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
            startTime: task.startTime
        )
        let content = ActivityContent(state: state, staleDate: nil)
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
                _ = try Activity.request(
                    attributes: attributes,
                    content: content,
                    style: .standard,
                    alertConfiguration: alert,
                    start: activationDate
                )
            } else if activationDate <= now {
                _ = try Activity.request(
                    attributes: attributes,
                    content: content,
                    pushType: nil
                )
            }
        } catch {
            print("Live Activity could not be started: \(error.localizedDescription)")
        }
    }

    private static func endAll() async {
        for activity in Activity<RitvaraActivityAttributes>.activities {
            await activity.end(
                ActivityContent(state: activity.content.state, staleDate: nil),
                dismissalPolicy: .immediate
            )
        }
    }
}
