import SwiftUI

struct TaskDetailView: View {
    // NOU: @Binding - "împrumută" taskul din ContentView, orice schimbare aici se vede și acolo
    let task: TaskItem
    
    var body: some View {
        // NOU: Form - layout gata făcut pentru ecrane cu date de completat (ca în Settings)
        Form {
            Section("Task") {
                Text(task.title)
                Text(task.category.rawValue)
                    .foregroundStyle(task.category.color)
            }
            
            Section("Notes") {
                // NOU: TextField cu $task.notes - câmp editabil legat direct de nota taskului
                TextField("Add notes...", text: Bindable(task).notes, axis: .vertical)
                    .lineLimit(3...6)
            }
            
            Section {
                // NOU: Toggle - comutator vizual, legat de isCompleted
                Toggle("Completed", isOn: Bindable(task).isCompleted)
            }
        }
        .navigationTitle("Task Details")
    }
}

// NOTĂ: am scos #Preview de aici temporar - are nevoie de un parametru special (Binding constant)
// pe care-l putem adăuga mai târziu dacă vrei preview izolat pentru acest ecran
