import SwiftUI

struct DailyBriefingCard: View {
    let date: Date
    let tasks: [TaskItem]
    let previousDayTasks: [TaskItem]

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var activeTasks: [TaskItem] { tasks.filter { !$0.isSkipped } }
    private var completed: Int { activeTasks.filter(\.isCompleted).count }
    private var remaining: [TaskItem] {
        activeTasks.filter { !$0.isCompleted }.sorted { $0.startTime < $1.startTime }
    }

    private var progress: Double {
        guard !activeTasks.isEmpty else { return 0 }
        return Double(completed) / Double(activeTasks.count)
    }

    private var previousProgress: Double? {
        let active = previousDayTasks.filter { !$0.isSkipped }
        guard !active.isEmpty else { return nil }
        return Double(active.filter(\.isCompleted).count) / Double(active.count)
    }

    private var isComplete: Bool { !activeTasks.isEmpty && remaining.isEmpty }

    private var highlightedTask: TaskItem? {
        let now = Date()
        if Calendar.current.isDateInToday(date) {
            return remaining.first(where: { $0.startTime >= now }) ?? remaining.first
        }
        return remaining.first
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(AppTheme.accent.opacity(0.14))
                    Image(systemName: isComplete ? "checkmark.seal.fill" : "sparkles")
                        .font(.title3.bold())
                        .foregroundStyle(AppTheme.accent)
                        .symbolEffect(
                            .bounce,
                            options: reduceMotion || !isComplete ? .nonRepeating : .repeat(1),
                            value: isComplete
                        )
                }
                .frame(width: 46, height: 46)

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.headline)
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }

                Spacer(minLength: 0)
            }

            if !activeTasks.isEmpty {
                ProgressView(value: progress)
                    .tint(AppTheme.accent)
                    .animation(reduceMotion ? nil : .easeInOut(duration: 0.35), value: progress)

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 10) { metrics }
                    VStack(spacing: 10) { metrics }
                }
            }
        }
        .padding(18)
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 22))
        .overlay {
            RoundedRectangle(cornerRadius: 22)
                .stroke(isComplete ? AppTheme.accent : AppTheme.border, lineWidth: isComplete ? 2 : 1)
        }
        .shadow(
            color: isComplete ? AppTheme.accent.opacity(0.2) : .clear,
            radius: reduceMotion ? 0 : 18
        )
        .accessibilityElement(children: .contain)
    }

    private var title: LocalizedStringKey {
        if activeTasks.isEmpty { return "A clear day" }
        if isComplete { return "Day complete" }
        if completed == 0 { return "Ready when you are" }
        return "Keep the momentum"
    }

    private var subtitle: String {
        guard let highlightedTask else {
            return activeTasks.isEmpty
                ? String(localized: "No activities planned for this day.")
                : String(localized: "Everything planned is complete. Well done!")
        }

        let time = highlightedTask.startTime.formatted(date: .omitted, time: .shortened)
        if Calendar.current.isDateInToday(date), highlightedTask.startTime < Date() {
            return String(localized: "Waiting: \(highlightedTask.title) · \(time)")
        }
        return String(localized: "Next: \(highlightedTask.title) · \(time)")
    }

    @ViewBuilder
    private var metrics: some View {
        metric("Done", value: "\(completed)/\(activeTasks.count)", icon: "checkmark.circle.fill")
        metric("Remaining", value: "\(remaining.count)", icon: "hourglass")
        metric("Previous day", value: comparisonText, icon: comparisonIcon)
    }

    private var comparisonText: String {
        guard let previousProgress else { return "—" }
        let difference = Int(((progress - previousProgress) * 100).rounded())
        if difference == 0 { return "=" }
        return difference > 0 ? "+\(difference)%" : "\(difference)%"
    }

    private var comparisonIcon: String {
        guard let previousProgress else { return "minus" }
        if progress > previousProgress { return "arrow.up.right" }
        if progress < previousProgress { return "arrow.down.right" }
        return "equal"
    }

    private func metric(
        _ label: LocalizedStringKey,
        value: String,
        icon: String
    ) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(AppTheme.accent)
            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.subheadline.bold().monospacedDigit())
                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .background(AppTheme.accent.opacity(0.07), in: RoundedRectangle(cornerRadius: 12))
    }
}
