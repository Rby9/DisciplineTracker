import SwiftUI
import SwiftData
import Foundation

struct TaskDetailView: View {

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // MARK: - Properties

    @Bindable var task: TaskItem

    // MARK: - State

    @State private var currentTime = Date()
    @State private var isEditing = false
    @State private var isConverting = false
    @State private var showDeleteConfirmation = false

    @State private var previousStartTime: Date?
    @State private var lastRescheduledTime: Date?

    @State private var showError = false
    @State private var errorMessage = ""

    private let accent = Color(hex: "8B7CFF")

    // MARK: - Computed Properties

    private var estimatedTimeRemaining: String {
        if task.isSkipped { return "Skipped" }
        if task.isCompleted {
            return "Completed"
        }

        let secondsRemaining =
            task.startTime.timeIntervalSince(currentTime)

        if secondsRemaining <= 0 {
            return "Overdue by \(formatTime(abs(secondsRemaining)))"
        }

        return "Starts in \(formatTime(secondsRemaining))"
    }

    private var statusColor: Color {
        if task.isSkipped { return .orange }
        if task.isCompleted {
            return task.category.color
        }

        return task.startTime <= currentTime
            ? .red.opacity(0.8)
            : accent
    }

    private var canUndoReschedule: Bool {
        previousStartTime != nil &&
        lastRescheduledTime == task.startTime
    }

    // MARK: - Body

    var body: some View {
        AppForm {
            taskSection
            completionSection

            if task.isPending {
                rescheduleSection
            }

            notesSection
            if task.seriesID == nil {
                Section {
                    Button { isConverting = true } label: {
                        Label("Make recurring", systemImage: "repeat")
                    }
                } footer: {
                    Text("Keep this task and plan future occurrences of a routine.")
                }
            }
            deleteSection
        }
        .navigationTitle("Task Details")
        .navigationBarTitleDisplayMode(.inline)
        .tint(accent)
        .toolbar {
            editToolbar
        }
        .sheet(isPresented: $isConverting) {
            ConvertTaskToRoutineView(task: task)
        }
        .sheet(isPresented: $isEditing) {
            EditTaskView(task: task)
        }
        .alert(
            "Delete Task?",
            isPresented: $showDeleteConfirmation
        ) {
            Button("Cancel", role: .cancel) {}

            Button("Delete", role: .destructive) {
                deleteTask()
            }
        } message: {
            Text(
                task.seriesID == nil
                    ? "Are you sure you want to delete this task?"
                    : "Only this occurrence will be deleted. The other days of the routine will remain."
            )
        }
        .alert(
            "Could not save changes",
            isPresented: $showError
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .task {
            await startTimer()
        }
    }

    // MARK: - Task Section

    private var taskSection: some View {
        Section("Task") {
            Text(task.title)
                .font(.headline)

            Text(task.category.rawValue)
                .foregroundStyle(task.category.color)

            LabeledContent("Date") {
                Text(
                    task.startTime,
                    format: .dateTime
                        .day()
                        .month(.abbreviated)
                        .year()
                )
            }

            LabeledContent("Time") {
                Text(task.startTime, style: .time)
            }

            Text(estimatedTimeRemaining)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(statusColor)
                .contentTransition(.numericText())
                .animation(
                    .easeInOut(duration: 0.3),
                    value: estimatedTimeRemaining
                )

            if task.seriesID != nil {
                Label(
                    "Part of a routine",
                    systemImage: "repeat"
                )
                .font(.footnote)
                .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Completion Section

    private var completionSection: some View {
        Section {
            Picker("Status", selection: Binding(
                get: { task.status },
                set: { updateStatus($0) }
            )) {
                ForEach(TaskStatus.allCases) { status in
                    Label(status.rawValue, systemImage: status.symbol).tag(status)
                }
            }
        } footer: {
            Text("Skipped stays in your plan, but is no longer pending and receives no reminders. Progress counts only completed tasks.")
        }
    }

    private func updateStatus(_ status: TaskStatus) {
        do {
            try TaskStatusStore.set(status, for: task, in: modelContext)
            currentTime = Date()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    // MARK: - Reschedule Section

    private var rescheduleSection: some View {
        Section {
            Button {
                rescheduleFromNow(minutes: 15)
            } label: {
                Label(
                    "In 15 minutes",
                    systemImage: "clock.arrow.circlepath"
                )
            }

            Button {
                rescheduleFromNow(minutes: 60)
            } label: {
                Label(
                    "In 1 hour",
                    systemImage: "clock"
                )
            }

            Button {
                rescheduleForTomorrow()
            } label: {
                Label(
                    "Tomorrow, same time",
                    systemImage: "calendar.badge.clock"
                )
            }

            if canUndoReschedule {
                Button {
                    undoReschedule()
                } label: {
                    Label(
                        "Undo last reschedule",
                        systemImage: "arrow.uturn.backward"
                    )
                }
            }
        } header: {
            Text("Reschedule")
        } footer: {
            Text(
                task.seriesID == nil
                    ? "The first two options use the current time. Tomorrow keeps the task's scheduled hour."
                    : "Only this occurrence moves. The routine's other days stay unchanged. Tomorrow may already contain another occurrence."
            )
        }
    }

    // MARK: - Notes Section

    private var notesSection: some View {
        Section("Notes") {
            TextField(
                "Add notes...",
                text: $task.notes,
                axis: .vertical
            )
            .lineLimit(3...6)
        }
    }

    // MARK: - Delete Section

    private var deleteSection: some View {
        Section {
            Button(
                task.seriesID == nil
                    ? "Delete Task"
                    : "Delete This Occurrence",
                role: .destructive
            ) {
                showDeleteConfirmation = true
            }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var editToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button("Edit") {
                isEditing = true
            }
        }
    }

    // MARK: - Rescheduling Actions

    private func rescheduleFromNow(minutes: Int) {
        guard let newDate = Calendar.current.date(
            byAdding: .minute,
            value: minutes,
            to: Date()
        ) else {
            displayDateError()
            return
        }

        moveTask(to: newDate)
    }

    private func rescheduleForTomorrow() {
        let calendar = Calendar.current

        guard let tomorrow = calendar.date(
            byAdding: .day,
            value: 1,
            to: calendar.startOfDay(for: Date())
        ) else {
            displayDateError()
            return
        }

        let clock = calendar.dateComponents(
            [.hour, .minute],
            from: task.startTime
        )

        guard let newDate = calendar.date(
            bySettingHour: clock.hour ?? 0,
            minute: clock.minute ?? 0,
            second: 0,
            of: tomorrow
        ),
        calendar.isDate(newDate, inSameDayAs: tomorrow) else {
            displayDateError()
            return
        }

        moveTask(to: newDate)
    }

    private func moveTask(to newDate: Date) {
        let oldDate = task.startTime

        guard newDate != oldDate else {
            return
        }

        task.startTime = newDate

        do {
            try modelContext.save()

            previousStartTime = oldDate
            lastRescheduledTime = newDate
            currentTime = Date()

            NotificationManager.shared
                .scheduleNotifications(for: task)

        } catch {
            task.startTime = oldDate
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func undoReschedule() {
        guard canUndoReschedule,
              let previousDate = previousStartTime else {
            return
        }

        let currentDate = task.startTime
        task.startTime = previousDate

        do {
            try modelContext.save()

            previousStartTime = nil
            lastRescheduledTime = nil
            currentTime = Date()

            NotificationManager.shared
                .scheduleNotifications(for: task)

        } catch {
            task.startTime = currentDate
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    private func displayDateError() {
        errorMessage = "The new date could not be calculated."
        showError = true
    }

    // MARK: - Delete Action

    private func deleteTask() {
        var beganChanges = false
        do {
            try modelContext.save()
            beganChanges = true
            if let seriesID = task.seriesID {
                let routines = try modelContext.fetch(FetchDescriptor<TaskSeries>())
                if let routine = routines.first(where: { $0.id == seriesID }) {
                    let key = JournalEntry.key(for: task.originalScheduledDate ?? task.startTime)
                    var exclusions = routine.excludedDayKeys ?? []
                    if !exclusions.contains(key) { exclusions.append(key) }
                    routine.excludedDayKeys = exclusions
                }
            }
            modelContext.delete(task)
            try modelContext.save()
            NotificationManager.shared.refreshNotifications()
            dismiss()
        } catch {
            if beganChanges { modelContext.rollback() }
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    // MARK: - Time Formatting

    private func formatTime(_ seconds: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.day, .hour, .minute]
        formatter.unitsStyle = .abbreviated
        formatter.maximumUnitCount = 2
        formatter.zeroFormattingBehavior = .dropAll

        return formatter.string(from: seconds) ?? "0m"
    }

    // MARK: - Timer

    private func startTimer() async {
        currentTime = Date()

        while !Task.isCancelled {
            do {
                try await Task.sleep(for: .seconds(30))
            } catch {
                return
            }

            currentTime = Date()
        }
    }
}
