import SwiftUI
import SwiftData

struct EditTaskView: View {
    
    // MARK: - Environment
    
    @Environment(\.dismiss) private var dismiss
    
    
    // MARK: - Properties
    
    @Bindable var task: TaskItem
    
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            Form {
                taskSection
                notesSection
            }
            .navigationTitle("Edit Task")
            .toolbar {
                toolbar
            }
        }
    }
    
    
    // MARK: - View Components
    
    private var taskSection: some View {
        Section("Task") {
            TextField(
                "Title",
                text: $task.title
            )
            
            Picker(
                "Category",
                selection: $task.category
            ) {
                ForEach(
                    TaskCategory.allCases,
                    id: \.self
                ) { category in
                    Text(category.rawValue)
                        .tag(category)
                }
            }
            
            DatePicker(
                "Time",
                selection: $task.startTime,
                displayedComponents: [
                    .date,
                    .hourAndMinute
                ]
            )
        }
    }
    
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
    
    
    // MARK: - Toolbar
    
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(
            placement: .cancellationAction
        ) {
            Button("Cancel") {
                dismiss()
            }
        }
        
        ToolbarItem(
            placement: .confirmationAction
        ) {
            Button("Done") {
                saveChanges()
            }
        }
    }
    
    
    // MARK: - Actions
    
    private func saveChanges() {
        NotificationManager.shared
            .cancelNotifications(for: task)
        
        NotificationManager.shared
            .scheduleNotifications(for: task)
        
        dismiss()
    }
}


#Preview {
    EditTaskView(
        task: TaskItem(
            title: "Example Task",
            category: .other,
            startTime: Date(),
            isCompleted: false,
            notes: ""
        )
    )
}
