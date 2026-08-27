import SwiftUI
import SwiftData

struct EditTaskView: View {

    @Bindable var task: TaskItem

    @Environment(\.dismiss) private var dismiss

    var body: some View {

        NavigationStack {

            Form {

                Section("Task") {

                    TextField(
                        "Title",
                        text: $task.title
                    )

                    Picker(
                        "Category",
                        selection: $task.category
                    ) {
                        ForEach(TaskCategory.allCases, id: \.self) { category in
                            Text(category.rawValue)
                                .tag(category)
                        }
                    }

                    DatePicker(
                        "Time",
                        selection: $task.startTime,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                }

                Section("Notes") {

                    TextField(
                        "Add notes...",
                        text: $task.notes,
                        axis: .vertical
                    )
                    .lineLimit(3...6)
                }
            }
            .navigationTitle("Edit Task")
            .toolbar {

                ToolbarItem(placement: .cancellationAction) {

                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {

                    Button("Done") {
                        
                        NotificationManager.shared.cancelNotifications(for: task)
                        
                        NotificationManager.shared.scheduleNotifications(for: task)
                        
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
