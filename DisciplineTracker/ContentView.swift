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
                
                ScrollView {
                    VStack(spacing: 0) {
                        
                        // MARK: - Header
                        
                        HStack {
                            Text("DisciplineTracker")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(.white)
                            
                            Spacer()
                            
                            Button {
                                // Profile - to be implemented later
                            } label: {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .frame(width: 38, height: 38)
                                    .background(
                                        Color(hex: "161426")
                                    )
                                    .overlay {
                                        Circle()
                                            .stroke(
                                                Color(hex: "2E2A4D"),
                                                lineWidth: 2
                                            )
                                    }
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        .padding(.bottom, 24)
                        
                        // MARK: - Progress
                        
                        ProgressHeaderView(
                            progress: progress,
                            completedTask: completedTasks,
                            totalTask: tasks.count
                        )
                        .padding(.bottom, 30)
                        
                        // MARK: - Tasks Header
                        
                        HStack {
                            Text("Today's Tasks")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundStyle(.white)
                            
                            Spacer()
                            
                            Button {
                                showAddTask = true
                            } label: {
                                Image(systemName: "plus")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(.white)
                                    .frame(width: 36, height: 36)
                                    .background(
                                        Color(hex: "8B7CFF")
                                    )
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                        
                        // MARK: - Task Cards
                        
                        LazyVStack(spacing: 12) {
                            ForEach(tasks) { task in
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
                            }
                        }
                        .padding(.horizontal, 16)
                        
                        // MARK: - Empty State
                        
                        if tasks.isEmpty {
                            VStack(spacing: 10) {
                                Image(systemName: "checkmark.circle")
                                    .font(.system(size: 40))
                                    .foregroundStyle(
                                        Color(hex: "8B7CFF")
                                    )
                                
                                Text("No tasks yet")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                                
                                Text("Tap + to add your first task.")
                                    .font(.subheadline)
                                    .foregroundStyle(
                                        .white.opacity(0.55)
                                    )
                            }
                            .padding(.top, 60)
                        }
                    }
                    .padding(.bottom, 30)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
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
