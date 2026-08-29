import SwiftUI
import Foundation
import SwiftData

struct TaskDetailView: View {

    @State private var currentTime = Date()
    @State private var isEditing = false
    @State private var showDeleteConfirmation = false

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var task: TaskItem

    private var estimatedTimeRemaining: String {

        if task.isCompleted {
            return "Completed"
        }

        let secondsRemaining = task.startTime.timeIntervalSince(currentTime)

        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.day, .hour, .minute]
        formatter.unitsStyle = .abbreviated
        formatter.maximumUnitCount = 2
        formatter.zeroFormattingBehavior = .dropAll

        if secondsRemaining <= 0 {

            let overdueText = formatter.string(
                from: abs(secondsRemaining)
            ) ?? "0m"

            return "Overdue by \(overdueText)"
        }

        let remainingText = formatter.string(
            from: secondsRemaining
        ) ?? "0m"

        return "Starts in \(remainingText)"
    }

    var body: some View {

        Form {

            Section("Task") {

                Text(task.title)

                Text(task.category.rawValue)
                    .foregroundStyle(task.category.color)

                Text(estimatedTimeRemaining)
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }

            Section("Notes") {

                TextField(
                    "Add notes...",
                    text: Bindable(task).notes,
                    axis: .vertical
                )
                .lineLimit(3...6)
            }

            Section {

                Toggle(
                    "Completed",
                    isOn: Bindable(task).isCompleted
                )
            }

            Section {

                Button("Delete Task", role: .destructive) {
                    showDeleteConfirmation = true
                }
            }
        }
        .navigationTitle("Task Details")

        .alert(
            "Delete Task?",
            isPresented: $showDeleteConfirmation
        ) {

            Button("Cancel", role: .cancel) {
            }

            Button("Delete", role: .destructive) {

                NotificationManager.shared.cancelNotifications(for: task)

                modelContext.delete(task)

                dismiss()
            }

        } message: {

            Text("Are you sure you want to delete this task?")
        }

        .toolbar {

            ToolbarItem(placement: .topBarTrailing) {

                Button("Edit") {
                    isEditing = true
                }
            }
        }

        .sheet(isPresented: $isEditing) {

            EditTaskView(task: task)
        }

        .task {

            while !Task.isCancelled {

                try? await Task.sleep(for: .seconds(30))

                currentTime = Date()
            }
        }
    }
}

#Preview {
    ContentView()
}
