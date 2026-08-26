import SwiftUI

struct ContentView: View {
    @State private var tasks: [TaskItem] = [
        TaskItem(id: UUID(), title: "Sala dimineață", category: .gym, startTime: Date(), isCompleted: false, notes: ""),
        TaskItem(id: UUID(), title: "Prânz", category: .food, startTime: Date(), isCompleted: false, notes: ""),
        TaskItem(id: UUID(), title: "Lucru", category: .work, startTime: Date(), isCompleted: false, notes: "")
    ]
    
    init(){
        for task in tasks {
            NotificationManager.shared.scheduleNotifications(for: task)
        }
    }
    
    var body: some View {
        // NOU: NavigationStack - "containerul" care permite trecerea de la un ecran la altul
        NavigationStack {
            // NOU: $tasks (cu $) în loc de tasks - dă acces de citire+scriere, nu doar citire
            List($tasks) { $task in
                // NOU: NavigationLink - face tot rândul apăsabil, deschide TaskDetailView la tap
                NavigationLink {
                    TaskDetailView(task: $task)
                } label: {
                    HStack {
                        Button {
                            toggleTask(task)
                        } label: {
                            Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                        }
                        // NOU: .buttonStyle(.plain) - fără asta, tot rândul ar reacționa vizual ca un buton mare
                        .buttonStyle(.plain)
                        
                        Text(task.title)
                            .strikethrough(task.isCompleted)
                        
                        Spacer()
                        Text(task.category.rawValue)
                            .foregroundStyle(task.category.color)
                    }
                }
            }
            // NOU: titlu afișat sus pe ecran
            .navigationTitle("Discipline Tracker")
        }
    }
    
    func toggleTask(_ task: TaskItem) {
        if let index = tasks.firstIndex(where: { $0.id == task.id }) {
            tasks[index].isCompleted.toggle()
            
            if tasks[index].isCompleted {
                NotificationManager.shared.cancelNotifications(for: tasks[index])
            }
        }
    }
}

#Preview {
    ContentView()
}
