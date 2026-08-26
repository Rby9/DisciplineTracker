import SwiftUI
import SwiftData

struct AddTaskView: View{
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var title = ""
    @State private var category: TaskCategory = .other
    @State private var startTime = Date()
    @State private var notes = ""
    
    var body: some View{
        
        NavigationStack{
            
            Form{
                
                Section("Task"){
                    
                    TextField("Title", text: $title)
                    
                    Picker("Category", selection: $category){
                        ForEach(TaskCategory.allCases, id: \.self) { category in Text(category.rawValue)
                                .tag(category)
                        }
                    }
                    
                    DatePicker(
                        "Time",
                        selection: $startTime,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                }
                
                Section("Notes"){
                    
                    TextField(
                        "Add notes...",
                        text: $notes,
                        axis: .vertical
                    )
                    .lineLimit(3...6)
                }
            }
            .navigationTitle("Add Task")
            .toolbar {
                ToolbarItem(placement: .cancellationAction){
                    
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction){
                    
                    Button("Save") {
                        
                        let task = TaskItem(
                            title: title,
                            category: category,
                            startTime: startTime,
                            isCompleted: false,
                            notes: notes
                        )
                        modelContext.insert(task)
                        
                        NotificationManager.shared.scheduleNotifications(for: task)
                        
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

#Preview {
    AddTaskView()
}
