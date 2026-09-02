import SwiftUI
import Foundation
import SwiftData

struct TaskDetailView: View {
    
    // MARK: - State
    
    @State private var currentTime = Date()
    @State private var isEditing = false
    @State private var showDeleteConfirmation = false
    
    
    // MARK: - Environment
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    
    // MARK: - Properties
    
    @Bindable var task: TaskItem
    
    
    // MARK: - Computed Properties
    
    private var estimatedTimeRemaining: String {
        if task.isCompleted {
            return "Completed"
        }
        
        let secondsRemaining =
            task.startTime.timeIntervalSince(currentTime)
        
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [
            .day,
            .hour,
            .minute
        ]
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
    
    
    // MARK: - Body
    
    var body: some View {
        Form {
            taskSection
            notesSection
            completionSection
            deleteSection
        }
        .navigationTitle("Task Details")
        .alert(
            "Delete Task?",
            isPresented: $showDeleteConfirmation
        ) {
            deleteAlertButtons
        } message: {
            Text("Are you sure you want to delete this task?")
        }
        .toolbar {
            editToolbar
        }
        .sheet(isPresented: $isEditing) {
            EditTaskView(task: task)
        }
        .task {
           await startTimer()
        }
    }
    
    
    // MARK: - View Components
    
    private var taskSection: some View {
        Section("Task") {
            Text(task.title)
            
            Text(task.category.rawValue)
                .foregroundStyle(task.category.color)
            
            Text(estimatedTimeRemaining)
                .font(.headline)
                .foregroundStyle(.secondary)
        }
    }
    
    private var notesSection: some View {
        Section("Notes") {
            TextField(
                "Add notes...",
                text: Bindable(task).notes,
                axis: .vertical
            )
            .lineLimit(3...6)
        }
    }
    
    private var completionSection: some View {
        Section {
            Toggle(
                "Completed",
                isOn: Bindable(task).isCompleted
            )
        }
    }
    
    private var deleteSection: some View {
        Section {
            Button(
                "Delete Task",
                role: .destructive
            ) {
                showDeleteConfirmation = true
            }
        }
    }
    
    
    // MARK: - Toolbar
    
    @ToolbarContentBuilder
    private var editToolbar: some ToolbarContent {
        ToolbarItem(
            placement: .topBarTrailing
        ) {
            Button("Edit") {
                isEditing = true
            }
        }
    }
    
    
    // MARK: - Alert
    
    @ViewBuilder
    private var deleteAlertButtons: some View {
        Button(
            "Cancel",
            role: .cancel
        ) {
        }
        
        Button(
            "Delete",
            role: .destructive
        ) {
            deleteTask()
        }
    }
    
    
    // MARK: - Actions
    
    private func deleteTask() {
        NotificationManager.shared
            .cancelNotifications(for: task)
        
        modelContext.delete(task)
        dismiss()
    }
    
    
    // MARK: - Timer
    
    private func startTimer() async {
        while !Task.isCancelled {
            try? await Task.sleep(
                for: .seconds(30)
            )
            
            currentTime = Date()
        }
    }
}


#Preview {
    ContentView()
}
