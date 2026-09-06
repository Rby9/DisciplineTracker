import SwiftUI
import SwiftData
import Foundation

struct WeeklyView: View {

    // MARK: - Environment

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    // MARK: - Properties

    @Query private var tasks: [TaskItem]

    @State private var selectedDate = Date()
    @State private var showAddTask = false
    @State private var showCalendar = false
    @State private var calendarDate = Date()
    @State private var selectedFilter: AgendaFilter = .all
    @State private var showCompleted = false

    private let accent = Color(hex: "8B7CFF")
    private let surface = Color(hex: "161426")
    private let border = Color(hex: "2E2A4D")

    // MARK: - Filters

    private enum AgendaFilter: String, CaseIterable {
        case all = "All"
        case pending = "Pending"
        case completed = "Completed"
    }

    // MARK: - Calendar

    private var calendar: Calendar {
        var result = Calendar.current
        result.firstWeekday = 2
        result.minimumDaysInFirstWeek = 4
        return result
    }

    private var weekStart: Date {
        let day = calendar.startOfDay(for: selectedDate)
        let weekday = calendar.component(.weekday, from: day)
        let daysSinceMonday = (weekday + 5) % 7

        return calendar.date(
            byAdding: .day,
            value: -daysSinceMonday,
            to: day
        ) ?? day
    }

    private var weekEnd: Date {
        calendar.date(
            byAdding: .day,
            value: 7,
            to: weekStart
        ) ?? weekStart
    }

    private var weekDates: [Date] {
        (0..<7).compactMap { offset in
            calendar.date(
                byAdding: .day,
                value: offset,
                to: weekStart
            )
        }
    }

    private var weekTitle: String {
        let lastDay = calendar.date(
            byAdding: .day,
            value: 6,
            to: weekStart
        ) ?? weekStart

        let formatter = DateIntervalFormatter()
        formatter.locale = Locale.current
        formatter.calendar = calendar
        formatter.dateStyle = .medium
        formatter.timeStyle = .none

        return formatter.string(
            from: weekStart,
            to: lastDay
        )
    }

    private var isCurrentWeek: Bool {
        let today = Date()
        return today >= weekStart && today < weekEnd
    }

    // MARK: - Task Properties

    private var weekTasks: [TaskItem] {
        tasks.filter {
            $0.startTime >= weekStart &&
            $0.startTime < weekEnd
        }
    }

    private var completedWeekTasks: Int {
        weekTasks.filter { $0.isCompleted }.count
    }

    private var weeklyProgress: Double {
        guard !weekTasks.isEmpty else {
            return 0
        }

        return Double(completedWeekTasks)
            / Double(weekTasks.count)
    }

    private var selectedDayTasks: [TaskItem] {
        tasksForDay(selectedDate)
    }

    private var pendingTasks: [TaskItem] {
        selectedDayTasks.filter { !$0.isCompleted }
    }

    private var completedTasks: [TaskItem] {
        selectedDayTasks.filter { $0.isCompleted }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0D0B16")
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        pageHeader
                        weekNavigation
                        weeklySummary
                        weekDayStrip
                        agendaHeader
                        filterBar
                        agendaContent
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
                calendarSheet
            }
        }
    }

    // MARK: - Page Header

    private var pageHeader: some View {
        HStack {
            Text("Weekly")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.white)

            Spacer()

            if !isCurrentWeek {
                Button {
                    selectDay(Date())
                } label: {
                    Text("This week")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(accent)
                        .padding(.horizontal, 12)
                        .frame(height: 40)
                        .background(surface)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }

            Button {
                calendarDate = selectedDate
                showCalendar = true
            } label: {
                Image(systemName: "calendar")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(accent)
                    .frame(width: 44, height: 44)
                    .background(surface)
                    .clipShape(
                        RoundedRectangle(cornerRadius: 14)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Choose a date")
        }
    }

    // MARK: - Week Navigation

    private var weekNavigation: some View {
        HStack(spacing: 8) {
            weekArrow(
                icon: "chevron.left",
                label: "Previous week",
                direction: -1
            )

            Text(weekTitle)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.85))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)

            weekArrow(
                icon: "chevron.right",
                label: "Next week",
                direction: 1
            )
        }
    }

    private func weekArrow(
        icon: String,
        label: String,
        direction: Int
    ) -> some View {
        Button {
            moveWeek(by: direction)
        } label: {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(.white.opacity(0.8))
                .frame(width: 44, height: 44)
                .background(surface)
                .clipShape(
                    RoundedRectangle(cornerRadius: 13)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    // MARK: - Weekly Summary

    private var weeklySummary: some View {
        VStack(spacing: 9) {
            HStack {
                Text(
                    weekTasks.isEmpty
                        ? "No tasks this week"
                        : "\(completedWeekTasks)/\(weekTasks.count) completed"
                )
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(.white.opacity(0.55))

                Spacer()

                Text("\(Int((weeklyProgress * 100).rounded()))%")
                    .font(.system(size: 14, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(accent)
            }

            ProgressView(value: weeklyProgress)
                .tint(accent)
                .accessibilityLabel("Weekly progress")
        }
    }

    // MARK: - Week Day Strip

    private var weekDayStrip: some View {
        HStack(spacing: 5) {
            ForEach(weekDates, id: \.self) { date in
                dayButton(date)
            }
        }
    }

    private func dayButton(_ date: Date) -> some View {
        let selected = calendar.isDate(
            date,
            inSameDayAs: selectedDate
        )
        let today = calendar.isDateInToday(date)
        let dayTasks = tasksForDay(date)
        let completed = dayTasks.filter { $0.isCompleted }.count

        return Button {
            selectDay(date)
        } label: {
            VStack(spacing: 6) {
                Text(
                    date,
                    format: .dateTime.weekday(.abbreviated)
                )
                .font(.system(size: 10, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)

                Text(date, format: .dateTime.day())
                    .font(.system(size: 17, weight: .bold))

                Text(
                    dayTasks.isEmpty
                        ? "—"
                        : "\(completed)/\(dayTasks.count)"
                )
                .font(.system(size: 9, weight: .medium))
                .monospacedDigit()
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            }
            .foregroundStyle(
                selected ? .white : .white.opacity(0.6)
            )
            .frame(maxWidth: .infinity)
            .frame(height: 76)
            .background(selected ? accent : surface)
            .clipShape(
                RoundedRectangle(cornerRadius: 14)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 14)
                    .stroke(
                        today
                            ? Color(hex: "A99EFF")
                            : Color.clear,
                        lineWidth: 1.5
                    )
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            date.formatted(date: .complete, time: .omitted)
        )
        .accessibilityValue(
            "\(completed) of \(dayTasks.count) completed"
        )
        .accessibilityAddTraits(
            selected ? .isSelected : []
        )
    }

    // MARK: - Agenda Header

    private var agendaHeader: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text(
                    selectedDate,
                    format: .dateTime
                        .weekday(.wide)
                        .day()
                        .month(.abbreviated)
                )
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(.white)

                Text(
                    "\(selectedDayTasks.count) tasks · \(pendingTasks.count) pending"
                )
                .font(.system(size: 12))
                .foregroundStyle(.white.opacity(0.5))
            }

            Spacer()

            Button {
                showAddTask = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(accent)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Add task for selected day")
        }
    }

    // MARK: - Filter Bar

    private var filterBar: some View {
        HStack(spacing: 4) {
            ForEach(AgendaFilter.allCases, id: \.self) { filter in
                Button {
                    selectedFilter = filter
                } label: {
                    Text(filter.rawValue)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(
                            selectedFilter == filter
                                ? .white
                                : .white.opacity(0.45)
                        )
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background {
                            if selectedFilter == filter {
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(accent.opacity(0.25))
                            }
                        }
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(
                    selectedFilter == filter ? .isSelected : []
                )
            }
        }
        .padding(4)
        .background(surface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Agenda Content

    @ViewBuilder
    private var agendaContent: some View {
        if selectedDayTasks.isEmpty {
            emptyMessage(
                icon: "calendar.badge.plus",
                title: "Your day is open",
                subtitle: "Tap + to plan your first task."
            )
        } else {
            switch selectedFilter {
            case .all:
                allTasksContent

            case .pending:
                if pendingTasks.isEmpty {
                    emptyMessage(
                        icon: "checkmark.circle",
                        title: "Nothing pending",
                        subtitle: "All tasks for this day are completed."
                    )
                } else {
                    agendaRows(pendingTasks)
                }

            case .completed:
                if completedTasks.isEmpty {
                    emptyMessage(
                        icon: "circle.dashed",
                        title: "No completed tasks",
                        subtitle: "Completed tasks will appear here."
                    )
                } else {
                    agendaRows(completedTasks)
                }
            }
        }
    }

    private var allTasksContent: some View {
        VStack(spacing: 18) {
            if pendingTasks.isEmpty {
                Label(
                    "All tasks completed",
                    systemImage: "checkmark.circle.fill"
                )
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(accent)
                .frame(maxWidth: .infinity, alignment: .leading)
            } else {
                agendaRows(pendingTasks)
            }

            if !completedTasks.isEmpty {
                DisclosureGroup(
                    isExpanded: $showCompleted
                ) {
                    agendaRows(completedTasks)
                        .padding(.top, 12)
                } label: {
                    Text("Completed · \(completedTasks.count)")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.65))
                }
                .tint(accent)
            }
        }
    }

    private func agendaRows(_ items: [TaskItem]) -> some View {
        LazyVStack(spacing: 0) {
            ForEach(items) { task in
                agendaRow(task)

                if task.id != items.last?.id {
                    Rectangle()
                        .fill(border.opacity(0.65))
                        .frame(height: 1)
                        .padding(.leading, 78)
                }
            }
        }
    }

    // MARK: - Agenda Row

    private func agendaRow(_ task: TaskItem) -> some View {
        HStack(spacing: 10) {
            NavigationLink {
                TaskDetailView(task: task)
            } label: {
                HStack(spacing: 12) {
                    Text(task.startTime, style: .time)
                        .font(.system(size: 12, weight: .medium))
                        .monospacedDigit()
                        .foregroundStyle(.white.opacity(0.5))
                        .frame(width: 58, alignment: .leading)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)

                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            task.category.color.opacity(
                                task.isCompleted ? 0.4 : 1
                            )
                        )
                        .frame(width: 3, height: 36)

                    VStack(alignment: .leading, spacing: 6) {
                        Text(task.title)
                            .font(
                                .system(size: 15, weight: .semibold)
                            )
                            .foregroundStyle(
                                task.isCompleted
                                    ? .white.opacity(0.5)
                                    : .white
                            )
                            .strikethrough(task.isCompleted)
                            .lineLimit(2)

                        HStack(spacing: 8) {
                            Text(task.category.rawValue)
                                .foregroundStyle(
                                    task.category.color
                                )

                            if !task.notes.trimmingCharacters(
                                in: .whitespacesAndNewlines
                            ).isEmpty {
                                Image(systemName: "note.text")
                                    .foregroundStyle(
                                        .white.opacity(0.4)
                                    )
                            }
                        }
                        .font(.system(size: 11, weight: .medium))
                    }

                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button {
                toggleTask(task)
            } label: {
                Image(
                    systemName: task.isCompleted
                        ? "checkmark.circle.fill"
                        : "circle"
                )
                .font(.system(size: 25))
                .foregroundStyle(
                    task.isCompleted
                        ? accent
                        : .white.opacity(0.35)
                )
                .symbolEffect(
                    .bounce,
                    value: task.isCompleted
                )
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel(
                task.isCompleted
                    ? "Mark \(task.title) as pending"
                    : "Complete \(task.title)"
            )
        }
        .padding(.vertical, 13)
    }

    // MARK: - Empty Message

    private func emptyMessage(
        icon: String,
        title: String,
        subtitle: String
    ) -> some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundStyle(accent)

            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white)

            Text(subtitle)
                .font(.system(size: 13))
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 30)
    }

    // MARK: - Calendar Sheet

    private var calendarSheet: some View {
        NavigationStack {
            ScrollView {
                DatePicker(
                    "Choose a date",
                    selection: $calendarDate,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
                .tint(accent)
                .padding(16)
            }
            .background(Color(hex: "0D0B16"))
            .navigationTitle("Choose a date")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showCalendar = false
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        selectDay(calendarDate)
                        showCalendar = false
                    }
                }
            }
        }
        .environment(\.calendar, calendar)
        .preferredColorScheme(.dark)
    }

    // MARK: - Helpers

    private func tasksForDay(_ date: Date) -> [TaskItem] {
        tasks.filter {
            calendar.isDate(
                $0.startTime,
                inSameDayAs: date
            )
        }
        .sorted {
            if $0.startTime == $1.startTime {
                return $0.id.uuidString < $1.id.uuidString
            }

            return $0.startTime < $1.startTime
        }
    }

    // MARK: - Actions

    private func selectDay(_ date: Date) {
        selectedDate = date
        showCompleted = false
    }

    private func moveWeek(by direction: Int) {
        guard let newDate = calendar.date(
            byAdding: .day,
            value: direction * 7,
            to: selectedDate
        ) else {
            return
        }

        selectDay(newDate)
    }

    private func toggleTask(_ task: TaskItem) {
        withAnimation(
            reduceMotion
                ? nil
                : .easeInOut(duration: 0.25)
        ) {
            task.isCompleted.toggle()
        }

        NotificationManager.shared
            .scheduleNotifications(for: task)
    }
}
