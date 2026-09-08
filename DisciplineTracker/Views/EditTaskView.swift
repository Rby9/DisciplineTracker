import SwiftUI
import SwiftData

struct EditTaskView: View {

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var showError = false
    @State private var errorMessage = ""

    // MARK: - Properties

    let task: TaskItem

    @State private var title: String
    @State private var category: TaskCategory
    @State private var startTime: Date
    @State private var notes: String
    @State private var reminderOffsets: [Int]

    // MARK: - Initialization

    init(task: TaskItem) {
        self.task = task

        _title = State(initialValue: task.title)
        _category = State(initialValue: task.category)
        _startTime = State(initialValue: task.startTime)
        _notes = State(initialValue: task.notes)
        _reminderOffsets = State(initialValue: task.effectiveReminderOffsets)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            AppForm {
                taskSection
                ReminderOptionsSection(offsets: $reminderOffsets, startTime: startTime)
                notesSection
            }
            .navigationTitle("Edit Task")
            .alert("Could not save task", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: { Text(errorMessage) }
            .toolbar {
                toolbar
            }
        }
    }

    // MARK: - View Components

    private var taskSection: some View {
        Section("Task") {
            TextField("Title", text: $title)

            Picker("Category", selection: $category) {
                ForEach(TaskCategory.allCases, id: \.self) { category in
                    Text(LocalizedStringKey(category.rawValue))
                        .tag(category)
                }
            }

            DatePicker(
                "Time",
                selection: $startTime,
                displayedComponents: [.date, .hourAndMinute]
            )
        }
    }

    private var notesSection: some View {
        Section("Notes") {
            TextField(
                "Add notes...",
                text: $notes,
                axis: .vertical
            )
            .lineLimit(3...6)
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") {
                dismiss()
            }
        }

        ToolbarItem(placement: .confirmationAction) {
            Button("Done") {
                saveChanges()
            }
            .disabled(
                title.trimmingCharacters(
                    in: .whitespacesAndNewlines
                ).isEmpty
            )
        }
    }

    // MARK: - Actions

    private func saveChanges() {
        var beganChanges = false
        do {
            try modelContext.save()
            beganChanges = true
            task.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
            task.category = category
            if task.startTime != startTime || task.effectiveReminderOffsets != ReminderPolicy.normalized(reminderOffsets) {
                task.snoozedUntil = nil
                task.snoozedStartTime = nil
            }
            if task.seriesID != nil && task.effectiveReminderOffsets != ReminderPolicy.normalized(reminderOffsets) {
                task.reminderOverride = true
            }
            task.reminderOffsets = ReminderPolicy.normalized(reminderOffsets)
            task.startTime = startTime
            task.notes = notes
            try modelContext.save()
            NotificationManager.shared.scheduleNotifications(for: task)
            if !reminderOffsets.isEmpty && ReminderPreferences.enabled {
                NotificationManager.shared.requestPermission()
            }
            dismiss()
        } catch {
            if beganChanges { modelContext.rollback() }
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}
