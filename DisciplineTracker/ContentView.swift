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
                        ZStack {
                            Circle()
                                .stroke(
                                    Color(hex: "2E2A4D"),
                                    lineWidth: 10
                                )
                            
                            Circle()
                                .trim(
                                    from: 0,
                                    to: progress
                                )
                                .stroke(
                                    Color(hex: "8B7CFF"),
                                    style: StrokeStyle(
                                        lineWidth: 10,
                                        lineCap: .round
                                    )
                                )
                                .rotationEffect(.degrees(-90))
                                .animation(
                                    .easeInOut,
                                    value: progress
                                )
                            
                            VStack(spacing: 2) {
                                Text("\(Int(progress * 100))%")
                                    .font(.system(
                                        size: 26,
                                        weight: .bold
                                    ))
                                    .foregroundStyle(.white)
                                
                                Text("Progress")
                                    .font(.caption)
                                    .foregroundStyle(
                                        .white.opacity(0.6)
                                    )
                            }
                        }
                        .frame(width: 120, height: 120)
                        
                        Text("Today's Progress")
                            .font(.headline)
                            .foregroundStyle(.white)
                        
                        Text("\(completedTasks) of \(tasks.count) tasks completed")
                            .font(.subheadline)
                            .foregroundStyle(
                                .white.opacity(0.6)
                            )
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 20)
                    
                    // MARK: - Tasks
                    
                    List(tasks) { task in
                        NavigationLink {
                            TaskDetailView(task: task)
                        } label: {
                            HStack(spacing: 12) {
                                Button {
                                    toggleTask(task)
                                } label: {
                                    Image(
                                        systemName: task.isCompleted
                                            ? "checkmark.circle.fill"
                                            : "circle"
                                    )
                                    .foregroundStyle(
                                        task.isCompleted
                                            ? Color(hex: "8B7CFF")
                                            : .white.opacity(0.6)
                                    )
                                    .font(.system(size: 24))
                                }
                                .buttonStyle(.plain)
                                
                                VStack(
                                    alignment: .leading,
                                    spacing: 4
                                ) {
                                    Text(task.title)
                                        .font(.headline)
                                        .foregroundStyle(.white)
                                        .strikethrough(
                                            task.isCompleted
                                        )
                                    
                                    Text(
                                        task.startTime,
                                        style: .time
                                    )
                                    .font(.subheadline)
                                    .foregroundStyle(
                                        .white.opacity(0.6)
                                    )
                                }
                                
                                Spacer()
                                
                                Text(task.category.rawValue)
                                    .font(.caption)
                                    .foregroundStyle(
                                        task.category.color
                                    )
                            }
                            .padding(.horizontal, 4)
                            .padding(.vertical, 6)
                            .background(
                                Color(hex: "161426")
                            )
                            .overlay {
                                RoundedRectangle(
                                    cornerRadius: 16
                                )
                                .stroke(
                                    Color(hex: "2E2A4D"),
                                    lineWidth: 2
                                )
                            }
                            .clipShape(
                                RoundedRectangle(
                                    cornerRadius: 16
                                )
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
