import SwiftUI
import SwiftData
import Foundation

struct ContentView: View {

    // MARK: - Environment

    @Environment(\.modelContext)
    private var modelContext

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    // MARK: - Data

    @Binding var selectedDate: Date

    @Query private var tasks: [TaskItem]

    // MARK: - State

    @State private var appearedTaskIDs: Set<UUID> = []
    @State private var showAddTask = false

    @State private var showStatusError = false
    @State private var statusErrorMessage = ""

    @State private var scrollOffset: CGFloat = 0
    @State private var progressReloadID = 0
    @State private var isProgressReloadArmed = false

    @State private var dayDirection: CGFloat = 1

    // MARK: - Calendar

    private var calendar: Calendar {
        Calendar.current
    }

    private var selectedDay: Date {
        calendar.startOfDay(for: selectedDate)
    }

    private var calendarSelection: Binding<Date> {
        Binding(
            get: { selectedDate },
            set: { selectDay($0) }
        )
    }

    // MARK: - Tasks

    private var selectedDayTasks: [TaskItem] {
        tasks.filter {
            calendar.isDate(
                $0.startTime,
                inSameDayAs: selectedDate
            )
        }
    }

    private var completedTasks: Int {
        selectedDayTasks.filter { $0.isCompleted }.count
    }

    private var progress: Double {
        guard !selectedDayTasks.isEmpty else {
            return 0
        }

        return Double(completedTasks)
            / Double(selectedDayTasks.count)
    }

    // MARK: - Day Animation

    private var dayAnimation: Animation {
        .easeInOut(
            duration: reduceMotion ? 0.15 : 0.28
        )
    }

    private var dayTransition: AnyTransition {
        if reduceMotion {
            return .opacity
        }

        return .asymmetric(
            insertion: .opacity.combined(
                with: .offset(x: dayDirection * 24)
            ),
            removal: .opacity.combined(
                with: .offset(x: dayDirection * -24)
            )
        )
    }

    // MARK: - Scroll Properties

    private var headerCollapse: CGFloat {
        min(max(scrollOffset / 90, 0), 1)
    }

    private var progressCollapse: CGFloat {
        min(max((scrollOffset - 25) / 190, 0), 1)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background
                    .ignoresSafeArea()

                mainScrollView
            }
            .toolbar(.hidden, for: .navigationBar)
            .alert(
                "Could not update task",
                isPresented: $showStatusError
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(statusErrorMessage)
            }
            .sheet(isPresented: $showAddTask) {
                AddTaskView(selectedDate: selectedDate)
            }
        }
    }

    // MARK: - Scroll View

    private var mainScrollView: some View {
        ScrollView {
            VStack(spacing: 0) {
                dashboardHeader
                progressHeader
                dateStrip
                animatedDayContent
            }
            .padding(.bottom, 30)
        }
        .onScrollGeometryChange(
            for: CGFloat.self
        ) { geometry in
            let offset =
                geometry.contentOffset.y
                + geometry.contentInsets.top

            return min(max(offset, 0), 240)
        } action: { _, newOffset in
            updateScroll(newOffset)
        }
    }

    // MARK: - Dashboard Header

    private var dashboardHeader: some View {
        DashboardHeader()
            .scaleEffect(
                reduceMotion
                    ? 1
                    : 1 - headerCollapse * 0.08,
                anchor: .top
            )
            .opacity(Double(1 - headerCollapse))
            .offset(
                y: reduceMotion
                    ? 0
                    : -headerCollapse * 12
            )
            .allowsHitTesting(headerCollapse < 0.9)
            .accessibilityHidden(headerCollapse >= 0.9)
    }

    // MARK: - Progress Header

    private var progressHeader: some View {
        ProgressHeaderView(
            progress: progress,
            completedTask: completedTasks,
            totalTask: selectedDayTasks.count,
            reloadID: progressReloadID
        )
        .scaleEffect(
            reduceMotion
                ? 1
                : 1 - progressCollapse * 0.35,
            anchor: .top
        )
        .opacity(Double(1 - progressCollapse))
        .offset(
            y: reduceMotion
                ? 0
                : -progressCollapse * 24
        )
        .accessibilityHidden(progressCollapse >= 0.95)
        .padding(.bottom, 28)
    }

    // MARK: - Calendar Strip

    private var dateStrip: some View {
        DateStripView(
            tasks: tasks,
            selectedDate: calendarSelection
        )
        .padding(.bottom, 28)
    }

    // MARK: - Animated Day Content

    private var animatedDayContent: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                tasksHeader

                if selectedDayTasks.isEmpty {
                    EmptyTaskView(
                        isToday: calendar.isDateInToday(
                            selectedDate
                        )
                    )
                } else {
                    taskList
                }
            }
            .frame(maxWidth: .infinity)
            .id(selectedDay)
            .transition(dayTransition)
        }
        .frame(maxWidth: .infinity)
        .animation(
            dayAnimation,
            value: selectedDay
        )
    }

    // MARK: - Tasks Header

    private var tasksHeader: some View {
        TasksHeader(
            selectedDate: selectedDate,
            isToday: calendar.isDateInToday(selectedDate),
            onAddTask: {
                showAddTask = true
            }
        )
    }

    // MARK: - Task List

    private var taskList: some View {
        LazyVStack(spacing: 12) {
            ForEach(selectedDayTasks) { task in
                NavigationLink {
                    TaskDetailView(task: task)
                } label: {
                    TaskCardView(
                        task: task,
                        onToggle: {
                            toggleTask(task)
                        }
                    )
                }
                .buttonStyle(.plain)
                .modifier(TaskStatusMenu(task: task))
                .opacity(
                    appearedTaskIDs.contains(task.id)
                        ? 1
                        : 0
                )
                .offset(
                    y: appearedTaskIDs.contains(task.id)
                        ? 0
                        : 18
                )
                .scaleEffect(
                    appearedTaskIDs.contains(task.id)
                        ? 1
                        : 0.97
                )
                .onAppear {
                    animateTaskAppearance(task)
                }
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Day Selection

    private func selectDay(_ date: Date) {
        let newDay = calendar.startOfDay(for: date)

        guard newDay != selectedDay else {
            return
        }

        dayDirection = newDay > selectedDay ? 1 : -1

        withAnimation(
            reduceMotion
                ? .easeInOut(duration: 0.15)
                : .spring(
                    response: 0.35,
                    dampingFraction: 0.8
                )
        ) {
            selectedDate = date
        }
    }

    // MARK: - Scroll Actions

    private func updateScroll(_ newOffset: CGFloat) {
        var transaction = Transaction()
        transaction.disablesAnimations = true

        withTransaction(transaction) {
            scrollOffset = newOffset
        }

        if newOffset >= 215 {
            isProgressReloadArmed = true
        }

        if isProgressReloadArmed && newOffset <= 90 {
            isProgressReloadArmed = false
            progressReloadID += 1
        }
    }

    // MARK: - Task Status

    private func toggleTask(_ task: TaskItem) {
        do {
            try withAnimation(
                reduceMotion
                    ? nil
                    : .easeInOut(duration: 0.25)
            ) {
                try TaskStatusStore.set(
                    task.isCompleted ? .pending : .completed,
                    for: task,
                    in: modelContext
                )
            }
        } catch {
            statusErrorMessage = error.localizedDescription
            showStatusError = true
        }
    }

    // MARK: - Card Appearance

    private func animateTaskAppearance(_ task: TaskItem) {
        guard !appearedTaskIDs.contains(task.id) else {
            return
        }

        withAnimation(
            reduceMotion
                ? .easeInOut(duration: 0.2)
                : .spring(
                    response: 0.45,
                    dampingFraction: 0.78
                )
        ) {
            _ = appearedTaskIDs.insert(task.id)
        }
    }
}
