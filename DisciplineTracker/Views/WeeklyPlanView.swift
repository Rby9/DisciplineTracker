import SwiftUI
import SwiftData

struct WeeklyPlanView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query(sort: \TaskItem.startTime) private var tasks: [TaskItem]

    @Binding var selectedDate: Date
    @State private var expandedDayKey: String?
    @State private var showAddTask = false
    @State private var showCalendar = false
    @State private var showMonthlyHistory = false
    @State private var calendarDate = Date()

    private var calendar: Calendar {
        var value = Calendar.current
        value.firstWeekday = 2
        value.minimumDaysInFirstWeek = 4
        return value
    }

    private var weekStart: Date {
        let day = calendar.startOfDay(for: selectedDate)
        let weekday = calendar.component(.weekday, from: day)
        return calendar.date(byAdding: .day, value: -((weekday + 5) % 7), to: day) ?? day
    }

    private var weekEnd: Date {
        calendar.date(byAdding: .day, value: 7, to: weekStart) ?? weekStart
    }

    private var weekDays: [WeeklyPlanDay] {
        (0..<7).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: weekStart) else {
                return nil
            }
            let items = tasks.filter { calendar.isDate($0.startTime, inSameDayAs: date) }
            return WeeklyPlanDay(date: date, tasks: items)
        }
    }

    private var weekTasks: [TaskItem] {
        tasks.filter { $0.startTime >= weekStart && $0.startTime < weekEnd }
    }

    private var priorityTasks: [TaskItem] {
        let now = Date()
        return weekTasks
            .filter(\.isPending)
            .sorted { lhs, rhs in
                let lhsOverdue = lhs.startTime < now
                let rhsOverdue = rhs.startTime < now
                if lhsOverdue != rhsOverdue { return lhsOverdue }
                return lhs.startTime < rhs.startTime
            }
            .prefix(3)
            .map { $0 }
    }

    private var isCurrentWeek: Bool {
        let now = Date()
        return now >= weekStart && now < weekEnd
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()

                ScrollView {
                    LazyVStack(spacing: 18) {
                        WeeklyPlanHeader(
                            weekStart: weekStart,
                            weekEnd: weekEnd,
                            isCurrentWeek: isCurrentWeek,
                            onPrevious: { moveWeek(-1) },
                            onNext: { moveWeek(1) },
                            onCurrentWeek: { selectWeek(containing: Date()) },
                            onOpenHistory: { showMonthlyHistory = true },
                            onChooseDate: {
                                calendarDate = selectedDate
                                showCalendar = true
                            }
                        )

                        WeeklyPlanOverview(tasks: weekTasks, days: weekDays)
                        WeeklyPlanChart(days: weekDays)
                        WeeklyCategoryBreakdown(tasks: weekTasks)

                        if !priorityTasks.isEmpty {
                            WeeklyPrioritySection(tasks: priorityTasks)
                        }

                        WeeklyDaysSection(
                            days: weekDays,
                            expandedDayKey: $expandedDayKey,
                            reduceMotion: reduceMotion,
                            onAddTask: { date in
                                selectedDate = date
                                showAddTask = true
                            }
                        )
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 12)
                    .padding(.bottom, 28)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showAddTask) {
                AddTaskView(selectedDate: selectedDate)
            }
            .sheet(isPresented: $showCalendar) {
                PlanDatePickerSheet(
                    selectedDate: $calendarDate,
                    tasks: tasks,
                    onCancel: { showCalendar = false },
                    onConfirm: {
                        selectedDate = calendarDate
                        expandedDayKey = JournalEntry.key(for: calendarDate)
                        showCalendar = false
                    }
                )
                .presentationDetents([.height(610)])
                .presentationDragIndicator(.visible)
            }
            .sheet(isPresented: $showMonthlyHistory) {
                MonthlyHistoryView(initialDate: selectedDate)
            }
        }
    }

    private func moveWeek(_ direction: Int) {
        guard let date = calendar.date(byAdding: .day, value: direction * 7, to: selectedDate) else {
            return
        }
        selectWeek(containing: date)
    }

    private func selectWeek(containing date: Date) {
        selectedDate = date
        expandedDayKey = nil
    }
}

private struct PlanDatePickerSheet: View {
    @Binding var selectedDate: Date
    let tasks: [TaskItem]
    let onCancel: () -> Void
    let onConfirm: () -> Void

    private var selectedTasks: [TaskItem] {
        tasks.filter { Calendar.current.isDate($0.startTime, inSameDayAs: selectedDate) }
    }

    private var completed: Int {
        selectedTasks.lazy.filter(\.isCompleted).count
    }

    private var routines: Int {
        selectedTasks.lazy.filter { $0.seriesID != nil }.count
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 14) {
                selectedDaySummary

                DatePicker(
                    "Choose a day",
                    selection: $selectedDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .tint(AppTheme.accent)
                .padding(.horizontal, 8)

                Button {
                    selectedDate = Date()
                } label: {
                    Label("Today", systemImage: "location.fill")
                        .font(.subheadline.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 44)
                        .background(AppTheme.accent.opacity(0.15), in: RoundedRectangle(cornerRadius: 13))
                }
                .buttonStyle(.plain)
                .foregroundStyle(AppTheme.accent)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Choose a day")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", action: onConfirm).fontWeight(.semibold)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private var selectedDaySummary: some View {
        HStack(spacing: 13) {
            Image(systemName: selectedTasks.isEmpty ? "calendar" : "calendar.badge.checkmark")
                .font(.title2.weight(.semibold))
                .foregroundStyle(AppTheme.accent)
                .frame(width: 46, height: 46)
                .background(AppTheme.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 13))

            VStack(alignment: .leading, spacing: 4) {
                Text(selectedDate, format: .dateTime.weekday(.wide).day().month(.wide))
                    .font(.headline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(selectedTasks.isEmpty
                     ? "No activities planned"
                     : "\(completed) of \(selectedTasks.count) completed")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 4)

            if routines > 0 {
                Label("\(routines)", systemImage: "repeat")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.accent)
            }
        }
        .padding(13)
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 17))
        .overlay { RoundedRectangle(cornerRadius: 17).stroke(AppTheme.border) }
    }
}

private struct WeeklyPlanDay: Identifiable {
    let date: Date
    let tasks: [TaskItem]

    var id: String { JournalEntry.key(for: date) }
    var completed: Int { tasks.lazy.filter(\.isCompleted).count }
    var pending: Int { tasks.lazy.filter(\.isPending).count }
    var routines: Int { tasks.lazy.filter { $0.seriesID != nil }.count }
    var progress: Double { tasks.isEmpty ? 0 : Double(completed) / Double(tasks.count) }
}

private struct WeeklyPlanHeader: View {
    let weekStart: Date
    let weekEnd: Date
    let isCurrentWeek: Bool
    let onPrevious: () -> Void
    let onNext: () -> Void
    let onCurrentWeek: () -> Void
    let onOpenHistory: () -> Void
    let onChooseDate: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Plan")
                        .font(.system(size: 28, weight: .bold))
                    Text("Organize your week at a glance")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.5))
                }
                .foregroundStyle(.white)

                Spacer()

                HStack(spacing: 8) {
                    if !isCurrentWeek {
                        Button("This week", action: onCurrentWeek)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppTheme.accent)
                            .padding(.horizontal, 12)
                            .frame(height: 40)
                            .background(AppTheme.surface, in: Capsule())
                    }

                    Button(action: onOpenHistory) {
                        Image(systemName: "calendar.badge.clock")
                            .font(.system(size: 17, weight: .semibold))
                            .frame(width: 40, height: 40)
                            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(AppTheme.accent)
                    .accessibilityLabel("Monthly history")

                    Button(action: onChooseDate) {
                        Image(systemName: "calendar")
                            .font(.system(size: 17, weight: .semibold))
                            .frame(width: 40, height: 40)
                            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(AppTheme.accent)
                    .accessibilityLabel("Choose a day")
                }
            }

            HStack(spacing: 8) {
                navigationButton("chevron.left", label: "Previous week", action: onPrevious)

                Text(weekStart..<weekEnd, format: .interval.day().month(.abbreviated))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white.opacity(0.85))
                    .frame(maxWidth: .infinity)

                navigationButton("chevron.right", label: "Next week", action: onNext)
            }
        }
    }

    private func navigationButton(
        _ icon: String,
        label: LocalizedStringKey,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.caption.bold())
                .frame(width: 44, height: 44)
                .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 13))
        }
        .buttonStyle(.plain)
        .foregroundStyle(.white.opacity(0.8))
        .accessibilityLabel(Text(label))
    }
}

private struct WeeklyPlanOverview: View {
    let tasks: [TaskItem]
    let days: [WeeklyPlanDay]

    private var completed: Int { tasks.lazy.filter(\.isCompleted).count }
    private var pending: Int { tasks.lazy.filter(\.isPending).count }
    private var progress: Double { tasks.isEmpty ? 0 : Double(completed) / Double(tasks.count) }
    private var busiestDay: WeeklyPlanDay? { days.max { $0.tasks.count < $1.tasks.count } }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 16) {
                ProgressRing(progress: progress)
                    .scaleEffect(0.63)
                    .frame(width: 82, height: 82)

                VStack(alignment: .leading, spacing: 5) {
                    Text("Weekly progress")
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text(tasks.isEmpty ? "No activities planned" : "\(completed) of \(tasks.count) completed")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.55))
                }
                Spacer()
            }

            HStack(spacing: 10) {
                metric(value: tasks.count, title: "Planned", icon: "calendar")
                metric(value: completed, title: "Completed", icon: "checkmark.circle.fill")
                metric(value: pending, title: "Pending", icon: "clock")
            }

            if let busiestDay, !busiestDay.tasks.isEmpty {
                Label {
                    Text("Busiest: \(busiestDay.date, format: .dateTime.weekday(.wide)) · \(busiestDay.tasks.count) activities")
                } icon: {
                    Image(systemName: "bolt.fill")
                        .foregroundStyle(.orange)
                }
                .font(.caption.weight(.medium))
                .foregroundStyle(.white.opacity(0.7))
            }
        }
        .padding(16)
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 20))
        .overlay { RoundedRectangle(cornerRadius: 20).stroke(AppTheme.border) }
    }

    private func metric(value: Int, title: LocalizedStringKey, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Image(systemName: icon).foregroundStyle(AppTheme.accent)
            Text("\(value)").font(.title3.bold()).monospacedDigit()
            Text(title).font(.caption2).foregroundStyle(.white.opacity(0.5))
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(11)
        .background(AppTheme.background.opacity(0.55), in: RoundedRectangle(cornerRadius: 14))
    }
}

private struct WeeklyPlanChart: View {
    let days: [WeeklyPlanDay]

    private var maximum: Int { max(days.map(\.tasks.count).max() ?? 0, 1) }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Weekly load")
                .font(.headline)
                .foregroundStyle(.white)

            HStack(alignment: .bottom, spacing: 9) {
                ForEach(days) { day in
                    VStack(spacing: 7) {
                        Text("\(day.tasks.count)")
                            .font(.caption2.weight(.semibold))
                            .monospacedDigit()
                            .foregroundStyle(.white.opacity(0.55))

                        GeometryReader { proxy in
                            VStack(spacing: 0) {
                                Spacer(minLength: 0)
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(day.tasks.isEmpty ? AppTheme.border : AppTheme.accent)
                                    .frame(height: max(8, proxy.size.height * CGFloat(day.tasks.count) / CGFloat(maximum)))
                                    .overlay(alignment: .bottom) {
                                        if day.completed > 0 {
                                            RoundedRectangle(cornerRadius: 6)
                                                .fill(.white.opacity(0.3))
                                                .frame(height: max(3, proxy.size.height * CGFloat(day.completed) / CGFloat(maximum)))
                                        }
                                    }
                            }
                        }
                        .frame(height: 82)

                        Text(day.date, format: .dateTime.weekday(.narrow))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(16)
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 20))
        .overlay { RoundedRectangle(cornerRadius: 20).stroke(AppTheme.border) }
        .accessibilityElement(children: .contain)
    }
}

private struct WeeklyCategoryBreakdown: View {
    let tasks: [TaskItem]

    private var categories: [(TaskCategory, Int)] {
        TaskCategory.allCases.compactMap { category in
            let count = tasks.lazy.filter { $0.category == category }.count
            return count == 0 ? nil : (category, count)
        }
        .sorted { $0.1 > $1.1 }
    }

    var body: some View {
        if !categories.isEmpty {
            VStack(alignment: .leading, spacing: 13) {
                Text("By category")
                    .font(.headline)
                    .foregroundStyle(.white)

                ForEach(categories, id: \.0) { category, count in
                    HStack(spacing: 10) {
                        Circle().fill(category.color).frame(width: 9, height: 9)
                        Text(LocalizedStringKey(category.rawValue))
                            .font(.subheadline.weight(.medium))
                        Spacer()
                        Text("\(count)")
                            .font(.subheadline.bold())
                            .monospacedDigit()
                    }
                    .foregroundStyle(.white.opacity(0.78))
                }
            }
            .padding(16)
            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 20))
            .overlay { RoundedRectangle(cornerRadius: 20).stroke(AppTheme.border) }
        }
    }
}

private struct WeeklyPrioritySection: View {
    let tasks: [TaskItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Coming up", systemImage: "sparkles")
                .font(.headline)
                .foregroundStyle(.white)

            ForEach(tasks) { task in
                NavigationLink {
                    TaskDetailView(task: task)
                } label: {
                    HStack(spacing: 12) {
                        Circle().fill(task.category.color).frame(width: 9, height: 9)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(task.title).font(.subheadline.weight(.semibold)).lineLimit(1)
                            Text(task.startTime, format: .dateTime.weekday(.abbreviated).hour().minute())
                                .font(.caption)
                                .foregroundStyle(task.startTime < Date() ? .orange : .secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right").font(.caption.bold()).foregroundStyle(.secondary)
                    }
                    .foregroundStyle(.white)
                    .padding(12)
                    .background(AppTheme.background.opacity(0.5), in: RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 20))
        .overlay { RoundedRectangle(cornerRadius: 20).stroke(AppTheme.border) }
    }
}

private struct WeeklyDaysSection: View {
    let days: [WeeklyPlanDay]
    @Binding var expandedDayKey: String?
    let reduceMotion: Bool
    let onAddTask: (Date) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Days")
                .font(.headline)
                .foregroundStyle(.white)

            ForEach(days) { day in
                WeeklyDayCard(
                    day: day,
                    isExpanded: expandedDayKey == day.id,
                    onToggle: {
                        withAnimation(reduceMotion ? nil : .spring(response: 0.38, dampingFraction: 0.86)) {
                            expandedDayKey = expandedDayKey == day.id ? nil : day.id
                        }
                    },
                    onAddTask: { onAddTask(day.date) }
                )
            }
        }
    }
}

private struct WeeklyDayCard: View {
    let day: WeeklyPlanDay
    let isExpanded: Bool
    let onToggle: () -> Void
    let onAddTask: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Button(action: onToggle) {
                WeeklyDayCardHeader(day: day, isExpanded: isExpanded)
            }
            .buttonStyle(.plain)
            .accessibilityValue(isExpanded ? "Expanded" : "Collapsed")

            if isExpanded {
                Divider().overlay(AppTheme.border)
                WeeklyDayCardDetails(tasks: day.tasks, onAddTask: onAddTask)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(Calendar.current.isDateInToday(day.date) ? AppTheme.accent.opacity(0.65) : AppTheme.border)
        }
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

private struct WeeklyDayCardHeader: View {
    let day: WeeklyPlanDay
    let isExpanded: Bool

    var body: some View {
        HStack(spacing: 13) {
            VStack(spacing: 2) {
                Text(day.date, format: .dateTime.weekday(.abbreviated))
                    .font(.caption.weight(.semibold))
                Text(day.date, format: .dateTime.day())
                    .font(.title3.bold())
            }
            .frame(width: 48)
            .foregroundStyle(Calendar.current.isDateInToday(day.date) ? AppTheme.accent : .white)

            VStack(alignment: .leading, spacing: 7) {
                HStack {
                    Text(day.tasks.isEmpty ? "Free day" : "\(day.tasks.count) activities")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    if day.routines > 0 {
                        Label("\(day.routines)", systemImage: "repeat")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(AppTheme.accent)
                    }
                }
                ProgressView(value: day.progress).tint(AppTheme.accent)
            }

            Image(systemName: "chevron.down")
                .font(.caption.bold())
                .foregroundStyle(.secondary)
                .rotationEffect(.degrees(isExpanded ? 180 : 0))
        }
        .foregroundStyle(.white)
        .padding(14)
        .contentShape(Rectangle())
    }
}

private struct WeeklyDayCardDetails: View {
    let tasks: [TaskItem]
    let onAddTask: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            if tasks.isEmpty {
                Text("Nothing planned yet")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
            } else {
                ForEach(tasks) { task in
                    WeeklyPlanTaskRow(task: task)
                }
            }

            Button(action: onAddTask) {
                Label("Add activity", systemImage: "plus")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 44)
            }
            .buttonStyle(.plain)
            .foregroundStyle(AppTheme.accent)
        }
    }
}

private struct WeeklyPlanTaskRow: View {
    let task: TaskItem

    var body: some View {
        NavigationLink {
            TaskDetailView(task: task)
        } label: {
            HStack(spacing: 11) {
                Text(task.startTime, style: .time)
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .frame(width: 52, alignment: .leading)
                Circle().fill(task.category.color).frame(width: 8, height: 8)
                Text(task.title)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
                if task.seriesID != nil {
                    Image(systemName: "repeat")
                        .font(.caption2.bold())
                        .foregroundStyle(AppTheme.accent)
                }
                Spacer()
                Image(systemName: task.status.symbol)
                    .foregroundStyle(task.isCompleted ? AppTheme.accent : Color.secondary)
            }
            .foregroundStyle(task.isCompleted ? Color.secondary : Color.white)
            .padding(.horizontal, 14)
            .frame(minHeight: 46)
        }
        .buttonStyle(.plain)
    }
}
