import SwiftUI
import SwiftData

struct ContentView: View {
    
    @Query private var tasks: [TaskItem]
    
    @State private var showAddTask = false
    
    private var completedTasks: Int {
        tasks.filter { $0.isCompleted }.count
    }
    
    private var progress: Double {
        guard !tasks.isEmpty else { return 0 }
        return Double(completedTasks) / Double(tasks.count)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                
                Color(hex: "0D0B16")
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    
                    // MARK: - Progress Section
                    
                    VStack(spacing: 12) {
                        ProgressHeaderView(
                            progress: progress,
                            completedTask: completedTasks,
                            totalTask: tasks.count
                        )
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 20)
                    
                    // MARK: - Tasks
                    
                    List(tasks) { task in
                        NavigationLink {
                            TaskDetailView(task: task)
                        } label: {
                            TaskCardView(
                                task: task,
                                onToggle: {
                                    toggleTask(task)
                                }
                            )
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                        .listRowInsets(
                            EdgeInsets(
                                top: 6,
                                leading: 16,
                                bottom: 6,
                                trailing: 16
                            )
                        )
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Discipline Tracker")
            .toolbarColorScheme(
                .dark,
                for: .navigationBar
            )
            .toolbar {
                ToolbarItem(
                    placement: .topBarTrailing
                ) {
                    Button {
                        showAddTask = true
                    } label: {
                        Image(systemName: "plus")
                            .foregroundStyle(.white)
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
            NotificationManager.shared.cancelNotifications(
                for: task
            )
        }
    }
}

#Preview {
    ContentView()
}

extension Color {
    
    init(hex: String) {
        let hex = hex.trimmingCharacters(
            in: CharacterSet.alphanumerics.inverted
        )
        
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        
        let red = Double((int >> 16) & 0xFF) / 255
        let green = Double((int >> 8) & 0xFF) / 255
        let blue = Double(int & 0xFF) / 255
        
        self.init(
            red: red,
            green: green,
            blue: blue
        )
    }
}
