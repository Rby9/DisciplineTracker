import SwiftUI
import SwiftData

struct ContentView: View {

    @Query private var tasks: [TaskItem]
    @State private var showAddTask = false
    
    var body: some View {

        NavigationStack {
            List(tasks) { task in
                NavigationLink {
                    TaskDetailView(task: task)
                } label: {
                    HStack {
                        Button {
                            toggleTask(task)
                        } label: {
                            Image(
                                systemName: task.isCompleted
                                    ? "checkmark.circle.fill"
                                    : "circle"
                            )
                        }
                        .buttonStyle(.plain)

                        Text(task.title)
                            .strikethrough(task.isCompleted)

                        Spacer()

                        Text(task.category.rawValue)
                            .foregroundStyle(task.category.color)
                    }
                }
            }
            .navigationTitle("Discipline Tracker")
            .toolbar {

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showAddTask = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showAddTask) {
                AddTaskView()
            }
        }
    }

    func toggleTask(_ task: TaskItem) {
        task.isCompleted.toggle()
        if task.isCompleted {
            NotificationManager.shared.cancelNotifications(for: task)
        }
    }
}

#Preview {
    ContentView()
}
