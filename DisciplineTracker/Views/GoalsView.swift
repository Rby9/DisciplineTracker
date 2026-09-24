import SwiftUI
import SwiftData

struct GoalsView: View {
    private enum GoalList: String, CaseIterable, Identifiable {
        case active
        case history

        var id: Self { self }
        var title: LocalizedStringResource {
            switch self {
            case .active: "Active"
            case .history: "History"
            }
        }
    }

    @Query(sort: \Goal.createdAt, order: .reverse) private var goals: [Goal]
    @Query private var tasks: [TaskItem]
    @State private var showAddGoal = false
    @State private var goalToDelete: Goal?
    @State private var selectedGoal: Goal?
    @State private var selectedList = GoalList.active

    private var activeGoals: [Goal] { goals.filter { $0.endDate > Date() } }
    private var pastGoals: [Goal] { goals.filter { $0.endDate <= Date() } }

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
                    LazyVStack(spacing: 16) {
                        GoalsHero(goalCount: goals.count, completedCount: completedGoalCount)

                        Picker("Goal list", selection: $selectedList) {
                            ForEach(GoalList.allCases) { list in
                                Text(list.title).tag(list)
                            }
                        }
                        .pickerStyle(.segmented)

                        if goals.isEmpty {
                            GoalsEmptyState { showAddGoal = true }
                        } else if selectedList == .active {
                            if activeGoals.isEmpty {
                                ContentUnavailableView(
                                    "No active goals",
                                    systemImage: "scope",
                                    description: Text("Create a new goal or review your finished periods in History.")
                                )
                            } else {
                                ForEach(activeGoals) { goal in
                                    GoalCard(
                                        goal: goal,
                                        completedTasks: completedTasks(for: goal),
                                        allTasks: matchingTasks(for: goal),
                                        open: { selectedGoal = goal },
                                        delete: { goalToDelete = goal }
                                    )
                                }
                            }
                        } else {
                            if pastGoals.isEmpty {
                                ContentUnavailableView(
                                    "No goal history yet",
                                    systemImage: "clock.arrow.circlepath",
                                    description: Text("Weekly and monthly goals appear here after their period ends.")
                                )
                            } else {
                                ForEach(pastGoals) { goal in
                                    GoalCard(
                                        goal: goal,
                                        completedTasks: completedTasks(for: goal),
                                        allTasks: matchingTasks(for: goal),
                                        open: { selectedGoal = goal },
                                        delete: { goalToDelete = goal }
                                    )
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 14)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .safeAreaInset(edge: .top) {
                GoalsHeader { showAddGoal = true }
            }
        }
        .sheet(isPresented: $showAddGoal) { AddGoalView() }
        .sheet(item: $selectedGoal) { goal in
            GoalDetailView(goal: goal)
        }
        .confirmationDialog(
            "Delete this goal?",
            isPresented: Binding(
                get: { goalToDelete != nil },
                set: { if !$0 { goalToDelete = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Delete goal", role: .destructive) {
                deleteSelectedGoal()
            }
            Button("Cancel", role: .cancel) { goalToDelete = nil }
        } message: {
            Text("Your activities are not deleted.")
        }
    }

    private var completedGoalCount: Int {
        goals.filter { completedTasks(for: $0).count >= $0.targetCount }.count
    }

    private func matchingTasks(for goal: Goal) -> [TaskItem] {
        tasks.filter { task in
            task.startTime >= goal.startDate &&
            task.startTime < goal.endDate &&
            (goal.category == nil || task.category == goal.category)
        }
    }

    private func completedTasks(for goal: Goal) -> [TaskItem] {
        matchingTasks(for: goal).filter(\.isCompleted)
    }

    private func deleteSelectedGoal() {
        guard let goalToDelete else { return }
        let context = goalToDelete.modelContext
        context?.delete(goalToDelete)
        do {
            try context?.save()
            self.goalToDelete = nil
        } catch {
            context?.rollback()
        }
    }
}

private struct GoalsHeader: View {
    let add: () -> Void

    var body: some View {
        HStack {
            Text("Goals")
                .font(.system(size: 28, weight: .bold))
            Spacer()
            Button(action: add) {
                Image(systemName: "plus")
                    .font(.system(size: 17, weight: .bold))
                    .frame(width: 44, height: 44)
                    .foregroundStyle(.white)
                    .background(AppTheme.accent, in: Circle())
            }
            .accessibilityLabel("Add goal")
        }
        .padding(.horizontal, 18)
        .padding(.top, 8)
        .padding(.bottom, 6)
        .background(Color(hex: "0F0E1E").opacity(0.96))
    }
}

private struct GoalsHero: View {
    let goalCount: Int
    let completedCount: Int

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: completedCount > 0 ? "sparkles" : "scope")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(AppTheme.accent)
            VStack(alignment: .leading, spacing: 4) {
                Text(completedCount > 0 ? "You are building momentum" : "Choose what matters")
                    .font(.headline)
                Text("\(completedCount) of \(goalCount) goals completed")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText())
            }
            Spacer()
        }
        .padding(18)
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 20))
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(AppTheme.border, lineWidth: 1)
        }
    }
}

private struct GoalsEmptyState: View {
    let add: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("No goals yet", systemImage: "scope")
        } description: {
            Text("Create a weekly or monthly target and Ritvara will track it from your completed activities.")
        } actions: {
            Button("Create first goal", action: add)
                .buttonStyle(.borderedProminent)
                .tint(AppTheme.accent)
        }
        .padding(.vertical, 36)
    }
}

private struct GoalCard: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let goal: Goal
    let completedTasks: [TaskItem]
    let allTasks: [TaskItem]
    let open: () -> Void
    let delete: () -> Void
    @State private var appeared = false

    private var progress: Double {
        min(Double(completedTasks.count) / Double(max(goal.targetCount, 1)), 1)
    }

    private var remaining: Int {
        max(goal.targetCount - completedTasks.count, 0)
    }

    private var daysRemaining: Int {
        max(Calendar.current.dateComponents([.day], from: Date(), to: goal.endDate).day ?? 0, 0)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(goal.title)
                        .font(.title3.bold())
                    HStack(spacing: 6) {
                        Text(goal.period.title)
                        Text("·")
                        if let category = goal.category {
                            Text(LocalizedStringKey(category.rawValue))
                        } else {
                            Text("All categories")
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                Spacer()
                Menu {
                    Button("Delete goal", role: .destructive, action: delete)
                } label: {
                    Image(systemName: "ellipsis")
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel("Goal options")
            }

            HStack(spacing: 20) {
                ZStack {
                    Circle().stroke(AppTheme.border, lineWidth: 11)
                    Circle()
                        .trim(from: 0, to: appeared ? progress : 0)
                        .stroke(AppTheme.accent, style: StrokeStyle(lineWidth: 11, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    VStack(spacing: 1) {
                        Text("\(Int((progress * 100).rounded()))%")
                            .font(.title3.bold())
                            .monospacedDigit()
                            .contentTransition(.numericText())
                        Text("done")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 104, height: 104)
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Goal progress")

                VStack(spacing: 12) {
                    GoalMetric(value: completedTasks.count, label: "Completed")
                    GoalMetric(value: remaining, label: "Remaining")
                    GoalMetric(value: daysRemaining, label: "Days left")
                }
            }

            GoalActivityChart(
                startDate: goal.startDate,
                endDate: goal.endDate,
                completedTasks: completedTasks,
                revealed: appeared
            )

            Text("\(completedTasks.count) completed from \(allTasks.count) planned in this period")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(18)
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 22))
        .overlay {
            RoundedRectangle(cornerRadius: 22)
                .stroke(progress >= 1 ? AppTheme.accent : AppTheme.border, lineWidth: progress >= 1 ? 2 : 1)
        }
        .shadow(color: progress >= 1 ? AppTheme.accent.opacity(0.22) : .clear, radius: 18)
        .contentShape(RoundedRectangle(cornerRadius: 22))
        .onTapGesture(perform: open)
        .onAppear {
            if reduceMotion {
                appeared = true
            } else {
                withAnimation(.spring(response: 0.75, dampingFraction: 0.82)) {
                    appeared = true
                }
            }
        }
        .animation(reduceMotion ? nil : .spring(response: 0.55, dampingFraction: 0.86), value: progress)
    }
}

private struct GoalMetric: View {
    let value: Int
    let label: LocalizedStringKey

    var body: some View {
        HStack {
            Text("\(value)")
                .font(.headline)
                .monospacedDigit()
                .contentTransition(.numericText())
            Spacer()
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

private struct GoalActivityChart: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let startDate: Date
    let endDate: Date
    let completedTasks: [TaskItem]
    let revealed: Bool

    private var days: [Date] {
        let calendar = Calendar.current
        let total = min(max(calendar.dateComponents([.day], from: startDate, to: endDate).day ?? 1, 1), 31)
        return (0..<total).compactMap { calendar.date(byAdding: .day, value: $0, to: startDate) }
    }

    private var maximum: Int {
        max(days.map(completedCount).max() ?? 0, 1)
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 3) {
            ForEach(days, id: \.self) { day in
                let count = completedCount(day)
                let fullHeight = max(6, 42 * CGFloat(count) / CGFloat(maximum))
                Capsule()
                    .fill(count > 0 ? AppTheme.accent : AppTheme.border)
                    .frame(maxWidth: .infinity)
                    .frame(height: revealed || reduceMotion ? fullHeight : 6)
                    .accessibilityLabel(day.formatted(date: .abbreviated, time: .omitted))
                    .accessibilityValue("\(count) completed")
            }
        }
        .frame(height: 44, alignment: .bottom)
        .animation(
            reduceMotion ? nil : .spring(response: 0.7, dampingFraction: 0.82),
            value: revealed
        )
    }

    private func completedCount(_ day: Date) -> Int {
        completedTasks.filter { Calendar.current.isDate($0.startTime, inSameDayAs: day) }.count
    }
}
