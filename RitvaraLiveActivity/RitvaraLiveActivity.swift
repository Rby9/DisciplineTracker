import ActivityKit
import SwiftUI
import WidgetKit

struct RitvaraActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        let dailyCompleted: Int
        let dailyTotal: Int
    }

    let taskID: UUID
    let title: String
    let startTime: Date
}

struct RitvaraLiveActivity: Widget {
    private let accent = Color(red: 139 / 255, green: 124 / 255, blue: 1)

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RitvaraActivityAttributes.self) { context in
            LockScreenActivityView(context: context, accent: accent)
                .activityBackgroundTint(Color(red: 22 / 255, green: 20 / 255, blue: 38 / 255))
                .activitySystemActionForegroundColor(.white)
                .widgetURL(URL(string: "ritvara://task/\(context.attributes.taskID.uuidString)"))
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    DailyProgressRing(completed: context.state.dailyCompleted, total: context.state.dailyTotal, accent: accent, size: 38)
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(context.attributes.title).font(.headline).lineLimit(1)
                        Text(context.attributes.startTime, style: .time)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    TaskCountdown(startTime: context.attributes.startTime)
                        .font(.headline.monospacedDigit())
                        .foregroundStyle(accent)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    ProgressView(value: Double(context.state.dailyCompleted), total: Double(max(context.state.dailyTotal, 1)))
                        .tint(accent)
                }
            } compactLeading: {
                DailyProgressRing(completed: context.state.dailyCompleted, total: context.state.dailyTotal, accent: accent, size: 22)
            } compactTrailing: {
                TaskCountdown(startTime: context.attributes.startTime)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(accent)
                    .frame(maxWidth: 52)
            } minimal: {
                DailyProgressRing(completed: context.state.dailyCompleted, total: context.state.dailyTotal, accent: accent, size: 22)
            }
            .widgetURL(URL(string: "ritvara://task/\(context.attributes.taskID.uuidString)"))
            .keylineTint(accent)
        }
    }
}

private struct LockScreenActivityView: View {
    let context: ActivityViewContext<RitvaraActivityAttributes>
    let accent: Color

    var body: some View {
        HStack(spacing: 14) {
            DailyProgressRing(completed: context.state.dailyCompleted, total: context.state.dailyTotal, accent: accent, size: 48)
            VStack(alignment: .leading, spacing: 4) {
                Text(context.attributes.title).font(.headline).lineLimit(1)
                Text("Ritvara • \(context.attributes.startTime, style: .time)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 8)
            TaskCountdown(startTime: context.attributes.startTime)
                .font(.headline.monospacedDigit())
                .foregroundStyle(accent)
        }
        .padding(.horizontal, 4)
    }
}

private struct TaskCountdown: View {
    let startTime: Date

    var body: some View {
        if startTime > .now {
            Text(timerInterval: Date.now...startTime, countsDown: true)
        } else {
            Text("Now")
        }
    }
}

private struct DailyProgressRing: View {
    let completed: Int
    let total: Int
    let accent: Color
    let size: CGFloat

    private var progress: Double {
        guard total > 0 else { return 0 }
        return min(max(Double(completed) / Double(total), 0), 1)
    }

    var body: some View {
        ZStack {
            Circle().stroke(accent.opacity(0.22), lineWidth: 3)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(accent, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text("\(Int((progress * 100).rounded()))")
                .font(.system(size: size * 0.28, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.6)
        }
        .frame(width: size, height: size)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Daily progress")
        .accessibilityValue("\(Int((progress * 100).rounded())) percent")
    }
}

#Preview("Live Activity", as: .content, using: RitvaraActivityAttributes(
    taskID: UUID(),
    title: "Morning training",
    startTime: .now.addingTimeInterval(1_800)
)) {
    RitvaraLiveActivity()
} contentStates: {
    RitvaraActivityAttributes.ContentState(dailyCompleted: 3, dailyTotal: 7)
}
