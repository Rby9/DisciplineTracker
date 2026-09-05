import SwiftUI
import SwiftData
import Foundation

struct ContentView: View {

    // MARK: - Environment

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    // MARK: - Properties

    @Query private var tasks: [TaskItem]

    @State private var appearedTaskIDs: Set<UUID> = []
    @State private var showAddTask = false
    @State private var selectedDate = Date()

    @State private var scrollOffset: CGFloat = 0
    @State private var progressReloadID = 0
    @State private var isProgressReloadArmed = false

    private var calendar: Calendar {
        Calendar.current
    }

    // MARK: - Task Properties

    private var selectedDayTasks: [TaskItem] {
        tasks.filter {
            calendar.isDate(
                $0.startTime,
                inSameDayAs: selectedDate
            )
        }
    }

    private var completedTasks: Int {
        selectedDayTasks.filter {
            $0.isCompleted
        }.count
    }

    private var progress: Double {
        guard !selectedDayTasks.isEmpty else {
            return 0
        }

        return Double(completedTasks)
            / Double(selectedDayTasks.count)
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
                background
                mainScrollView
            }
            .toolbar(
                .hidden,
                for: .navigationBar
            )
            .sheet(isPresented: $showAddTask) {
                AddTaskView(selectedDate: selectedDate)
            }
        }
    }

    // MARK: - Background

    private var background: some View {
        Color(hex: "0D0B16")
            .ignoresSafeArea()
    }

    // MARK: - Main Scroll View

    private var mainScrollView: some View {
        ScrollView {
            VStack(spacing: 0) {
                dashboardHeader
                progressHeader
                dateStrip
                tasksHeader
                taskList
                emptyState
            }
            .padding(.bottom, 30)
        }
        .onScrollGeometryChange(for: CGFloat.self) { geometry in
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
            .opacity(
                Double(1 - headerCollapse)
            )
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
        .opacity(
            Double(1 - progressCollapse)
        )
        .offset(
            y: reduceMotion
                ? 0
                : -progressCollapse * 24
        )
        .accessibilityHidden(progressCollapse >= 0.95)
        .padding(.bottom, 28)
    }

    // MARK: - Date Strip

    private var dateStrip: some View {
        DateStripView(
            tasks: tasks,
            selectedDate: $selectedDate
        )
        .padding(.bottom, 28)
    }

    // MARK: - Tasks Header

    private var tasksHeader: some View {
        TasksHeader(
            selectedDate: selectedDate,
            isToday: isToday(selectedDate),
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
                .opacity(
                    appearedTaskIDs.contains(task.id) ? 1 : 0
                )
                .offset(
                    y: appearedTaskIDs.contains(task.id) ? 0 : 18
                )
                .scaleEffect(
                    appearedTaskIDs.contains(task.id) ? 1 : 0.97
                )
                .onAppear {
                    animateTaskAppearance(task)
                }
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Empty State

    @ViewBuilder
    private var emptyState: some View {
        if selectedDayTasks.isEmpty {
            EmptyTaskView(
                isToday: isToday(selectedDate)
            )
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

    // MARK: - Task Actions

    private func toggleTask(_ task: TaskItem) {
        task.isCompleted.toggle()

        NotificationManager.shared
            .scheduleNotifications(for: task)
    }

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

    // MARK: - Helpers

    private func isToday(_ date: Date) -> Bool {
        calendar.isDateInToday(date)
    }
}
