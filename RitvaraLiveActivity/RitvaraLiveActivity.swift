import ActivityKit
import SwiftUI
import WidgetKit

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

struct RitvaraLiveActivity: Widget {
    private let accent = Color(red: 139 / 255, green: 124 / 255, blue: 1)

    var body: some WidgetConfiguration {
        ActivityConfiguration(for: RitvaraActivityAttributes.self) { context in
            LockScreenActivityView(context: context, accent: accent)
                .activityBackgroundTint(Color(red: 22 / 255, green: 20 / 255, blue: 38 / 255))
                .activitySystemActionForegroundColor(.white)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    DailyProgressRing(
                        completed: context.state.dailyCompleted,
                        total: context.state.dailyTotal,
                        accent: accent,
                        categoryColor: categoryColor(context.attributes.categoryColorHex),
                        size: 38
                    )
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(context.attributes.title)
                            .font(.headline)
                            .lineLimit(1)
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
                    VStack(alignment: .leading, spacing: 6) {
                        Label {
                            Text(context.attributes.categoryName)
                        } icon: {
                            Circle()
                                .fill(categoryColor(context.attributes.categoryColorHex))
                                .frame(width: 8, height: 8)
                        }
                        .font(.caption)
                        ProgressView(value: Double(context.state.dailyCompleted), total: Double(max(context.state.dailyTotal, 1)))
                            .tint(accent)
                    }
                }
            } compactLeading: {
                DailyProgressRing(completed: context.state.dailyCompleted, total: context.state.dailyTotal, accent: accent, categoryColor: categoryColor(context.attributes.categoryColorHex), size: 22)
            } compactTrailing: {
                TaskCountdown(startTime: context.attributes.startTime)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(accent)
                    .frame(maxWidth: 52)
            } minimal: {
                DailyProgressRing(completed: context.state.dailyCompleted, total: context.state.dailyTotal, accent: accent, categoryColor: categoryColor(context.attributes.categoryColorHex), size: 22)
            }
            .keylineTint(accent)
        }
    }
}

private struct LockScreenActivityView: View {
    let context: ActivityViewContext<RitvaraActivityAttributes>
    let accent: Color

    var body: some View {
        HStack(spacing: 14) {
            DailyProgressRing(completed: context.state.dailyCompleted, total: context.state.dailyTotal, accent: accent, categoryColor: categoryColor(context.attributes.categoryColorHex), size: 48)
            VStack(alignment: .leading, spacing: 4) {
                Text(context.attributes.title).font(.headline).lineLimit(1)
                HStack(spacing: 5) {
                    Circle()
                        .fill(categoryColor(context.attributes.categoryColorHex))
                        .frame(width: 7, height: 7)
                    Text("\(context.attributes.categoryName) • \(context.attributes.startTime, style: .time)")
                }
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
        TimelineView(.periodic(from: .now, by: 1)) { timeline in
            HStack(spacing: 0) {
                if timeline.date >= startTime {
                    Text("−")
                }
                Text(startTime, style: .timer)
            }
        }
        .accessibilityLabel("Time relative to activity start")
    }
}

private struct DailyProgressRing: View {
    let completed: Int
    let total: Int
    let accent: Color
    let categoryColor: Color
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
        .overlay(alignment: .bottomTrailing) {
            Circle()
                .fill(categoryColor)
                .frame(width: max(size * 0.24, 6), height: max(size * 0.24, 6))
                .overlay { Circle().stroke(.black.opacity(0.65), lineWidth: 1) }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Daily progress")
        .accessibilityValue("\(Int((progress * 100).rounded())) percent")
    }
}

#Preview("Live Activity", as: .content, using: RitvaraActivityAttributes(
    taskID: UUID(),
    title: "Morning training",
    startTime: .now.addingTimeInterval(1_800),
    categoryName: "Gym",
    categoryColorHex: "FF453A"
)) {
    RitvaraLiveActivity()
} contentStates: {
    RitvaraActivityAttributes.ContentState(dailyCompleted: 3, dailyTotal: 7)
}

private func categoryColor(_ hexCode: String) -> Color {
    let value = UInt64(hexCode, radix: 16) ?? 0x8E8E93
    return Color(
        red: Double((value >> 16) & 0xFF) / 255,
        green: Double((value >> 8) & 0xFF) / 255,
        blue: Double(value & 0xFF) / 255
    )
}
