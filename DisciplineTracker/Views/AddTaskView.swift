import SwiftUI
import SwiftData
import Foundation

struct AddTaskView: View {

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // MARK: - Properties

    @State private var title = ""
    @State private var category: TaskCategory = .other
    @State private var startTime: Date
    @State private var notes = ""

    // MARK: - Initialization

    init(selectedDate: Date) {
        let calendar = Calendar.current
        let now = Date()

        let currentTime = calendar.dateComponents(
            [.hour, .minute],
            from: now
        )

        let initialDate = calendar.date(
            bySettingHour: currentTime.hour ?? 0,
            minute: currentTime.minute ?? 0,
            second: 0,
            of: selectedDate
        ) ?? selectedDate

        _startTime = State(initialValue: initialDate)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                taskSection
                notesSection
            }
            .navigationTitle("Add Task")
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
                    Text(category.rawValue)
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
            Button("Save") {
                saveTask()
            }
            .disabled(
                title.trimmingCharacters(
                    in: .whitespacesAndNewlines
                ).isEmpty
            )
        }
    }

    // MARK: - Actions

    private func saveTask() {
        let task = TaskItem(
            title: title.trimmingCharacters(
                in: .whitespacesAndNewlines
            ),
            category: category,
            startTime: startTime,
            isCompleted: false,
            notes: notes
        )

        modelContext.insert(task)

        NotificationManager.shared
            .scheduleNotifications(for: task)

        dismiss()
    }
}
