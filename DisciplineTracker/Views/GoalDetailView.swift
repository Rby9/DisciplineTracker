import SwiftUI
import SwiftData

struct GoalDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var tasks: [TaskItem]
    let goal: Goal

    private var completedTasks: [TaskItem] {
        matchingTasks(in: goal.startDate..<goal.endDate).filter(\.isCompleted)
    }

    private var plannedCount: Int {
        matchingTasks(in: goal.startDate..<goal.endDate).count
    }

    private var previousCompleted: Int {
        let duration = goal.endDate.timeIntervalSince(goal.startDate)
        let start = goal.startDate.addingTimeInterval(-duration)
        return matchingTasks(in: start..<goal.startDate).filter(\.isCompleted).count
    }

    private var dayCounts: [GoalDayCount] {
        let calendar = Calendar.current
        let total = min(max(calendar.dateComponents([.day], from: goal.startDate, to: goal.endDate).day ?? 1, 1), 31)
        return (0..<total).compactMap { offset in
            guard let day = calendar.date(byAdding: .day, value: offset, to: goal.startDate) else { return nil }
            let count = completedTasks.filter { calendar.isDate($0.startTime, inSameDayAs: day) }.count
            return GoalDayCount(date: day, count: count)
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    stops: [
                        .init(color: Color(hex: "0F0E1E"), location: 0.5),
                        .init(color: Color(hex: "06050A"), location: 1)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 18) {
                        GoalDetailHero(title: goal.title, completed: completedTasks.count, target: goal.targetCount)
                        GoalDetailMetrics(
                            completed: completedTasks.count,
                            planned: plannedCount,
                            activeDays: dayCounts.filter { $0.count > 0 }.count,
                            bestDay: dayCounts.map(\.count).max() ?? 0
                        )
                        GoalComparisonCard(current: completedTasks.count, previous: previousCompleted)
                        GoalDetailedChart(days: dayCounts)
                        GoalCompletedActivities(tasks: completedTasks)
                    }
                    .padding(18)
                }
            }
            .navigationTitle("Goal details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func matchingTasks(in range: Range<Date>) -> [TaskItem] {
        tasks.filter { task in
            range.contains(task.startTime) &&
            (goal.category == nil || task.category == goal.category)
        }
    }
}

private struct GoalDetailHero: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let title: String
    let completed: Int
    let target: Int
    @State private var revealed = false

    private var progress: Double {
        min(Double(completed) / Double(max(target, 1)), 1)
    }

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle().stroke(Color(hex: "2E2A4D"), lineWidth: 14)
                Circle()
                    .trim(from: 0, to: revealed ? progress : 0)
                    .stroke(Color(hex: "8B7CFF"), style: StrokeStyle(lineWidth: 14, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 3) {
                    Text("\(Int((progress * 100).rounded()))%")
                        .font(.system(size: 34, weight: .bold))
                        .monospacedDigit()
                    Text("\(completed) of \(target)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 154, height: 154)

            Text(title)
                .font(.title2.bold())
                .multilineTextAlignment(.center)

            if progress >= 1 {
                Label("Goal achieved", systemImage: "sparkles")
                    .font(.headline)
                    .foregroundStyle(Color(hex: "8B7CFF"))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(22)
        .background(Color(hex: "161426"), in: RoundedRectangle(cornerRadius: 24))
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .stroke(progress >= 1 ? Color(hex: "8B7CFF") : Color(hex: "2E2A4D"), lineWidth: progress >= 1 ? 2 : 1)
        }
        .shadow(color: progress >= 1 ? Color(hex: "8B7CFF").opacity(0.25) : .clear, radius: 22)
        .onAppear {
            if reduceMotion {
                revealed = true
            } else {
                withAnimation(.spring(response: 0.85, dampingFraction: 0.8)) { revealed = true }
            }
        }
    }
}

private struct GoalDetailMetrics: View {
    let completed: Int
    let planned: Int
    let activeDays: Int
    let bestDay: Int

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            GoalStatistic(value: completed, title: "Completed", icon: "checkmark.circle.fill")
            GoalStatistic(value: planned, title: "Planned", icon: "calendar")
            GoalStatistic(value: activeDays, title: "Active days", icon: "flame.fill")
            GoalStatistic(value: bestDay, title: "Best day", icon: "star.fill")
        }
    }
}

private struct GoalStatistic: View {
    let value: Int
    let title: LocalizedStringKey
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon).foregroundStyle(Color(hex: "8B7CFF"))
            Text("\(value)")
                .font(.title.bold())
                .monospacedDigit()
                .contentTransition(.numericText())
            Text(title).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color(hex: "161426"), in: RoundedRectangle(cornerRadius: 18))
        .overlay { RoundedRectangle(cornerRadius: 18).stroke(Color(hex: "2E2A4D"), lineWidth: 1) }
    }
}

private struct GoalComparisonCard: View {
    let current: Int
    let previous: Int

    private var difference: Int { current - previous }

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: difference >= 0 ? "arrow.up.right" : "arrow.down.right")
                .font(.title2.bold())
                .foregroundStyle(difference >= 0 ? Color(hex: "8B7CFF") : .orange)
            VStack(alignment: .leading, spacing: 4) {
                Text("Compared with the previous period").font(.headline)
                if difference == 0 {
                    Text("Same number of completed activities")
                } else if difference > 0 {
                    Text("\(difference) more completed")
                } else {
                    Text("\(abs(difference)) fewer completed")
                }
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(18)
        .background(Color(hex: "161426"), in: RoundedRectangle(cornerRadius: 18))
        .overlay { RoundedRectangle(cornerRadius: 18).stroke(Color(hex: "2E2A4D"), lineWidth: 1) }
    }
}

private struct GoalDetailedChart: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let days: [GoalDayCount]
    @State private var revealed = false

    private var maximum: Int { max(days.map(\.count).max() ?? 0, 1) }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Daily activity").font(.headline)
            HStack(alignment: .bottom, spacing: 4) {
                ForEach(days) { day in
                    let height = max(8, 92 * CGFloat(day.count) / CGFloat(maximum))
                    VStack(spacing: 5) {
                        Capsule()
                            .fill(day.count > 0 ? Color(hex: "8B7CFF") : Color(hex: "2E2A4D"))
                            .frame(maxWidth: .infinity)
                            .frame(height: revealed || reduceMotion ? height : 8)
                        if days.count <= 7 {
                            Text(day.date, format: .dateTime.weekday(.narrow))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel(day.date.formatted(date: .complete, time: .omitted))
                    .accessibilityValue("\(day.count) completed")
                }
            }
            .frame(height: 112, alignment: .bottom)
        }
        .padding(18)
        .background(Color(hex: "161426"), in: RoundedRectangle(cornerRadius: 18))
        .overlay { RoundedRectangle(cornerRadius: 18).stroke(Color(hex: "2E2A4D"), lineWidth: 1) }
        .onAppear {
            if reduceMotion {
                revealed = true
            } else {
                withAnimation(.spring(response: 0.8, dampingFraction: 0.84)) { revealed = true }
            }
        }
    }
}

private struct GoalCompletedActivities: View {
    let tasks: [TaskItem]

    private var recentTasks: [TaskItem] {
        Array(tasks.sorted { $0.startTime > $1.startTime }.prefix(5))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("How you did it").font(.headline)
            if recentTasks.isEmpty {
                Text("Complete a matching activity to start building this story.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(recentTasks) { task in
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color(hex: "8B7CFF"))
                        VStack(alignment: .leading, spacing: 3) {
                            Text(task.title).font(.subheadline.weight(.semibold))
                            Text(task.startTime, format: .dateTime.day().month(.abbreviated).hour().minute())
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Color(hex: "161426"), in: RoundedRectangle(cornerRadius: 18))
        .overlay { RoundedRectangle(cornerRadius: 18).stroke(Color(hex: "2E2A4D"), lineWidth: 1) }
    }
}

private struct GoalDayCount: Identifiable {
    let date: Date
    let count: Int
    var id: Date { date }
}
