import SwiftUI
import SwiftData

struct ContentView: View {
    
    // MARK: - Properties
    
    @Query private var tasks: [TaskItem]
    
    @State private var showAddTask = false
    @State private var selectedDate = Date()
    
    private var calendar: Calendar {
        Calendar.current
    }
    
    
    // MARK: - Computed Properties
    
    private var selectedDayTasks: [TaskItem] {
        tasks.filter {
            calendar.isDate(
                $0.startTime,
                inSameDayAs: selectedDate
            )
        }
    }
    
    private var completedTasks: Int {
        selectedDayTasks.filter {
            $0.isCompleted
        }.count
    }
    
    private var progress: Double {
        guard !selectedDayTasks.isEmpty else {
            return 0
        }
        
        return Double(completedTasks)
            / Double(selectedDayTasks.count)
    }
    
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            ZStack {
                background
                
                ScrollView {
                    VStack(spacing: 0) {
                        dashboardHeader
                        progressHeader
                        dateStrip
                        tasksHeader
                        taskList
                        emptyState
                    }
                    .padding(.bottom, 30)
                }
            }
            .toolbar(
                .hidden,
                for: .navigationBar
            )
            .sheet(isPresented: $showAddTask) {
                AddTaskView(selectedDate: selectedDate)
            }
        }
    }
    
    
    // MARK: - View Components
    
    private var background: some View {
        Color(hex: "0D0B16")
            .ignoresSafeArea()
    }
    
    private var dashboardHeader: some View {
        DashboardHeader()
    }
    
    private var progressHeader: some View {
        ProgressHeaderView(
            progress: progress,
            completedTask: completedTasks,
            totalTask: selectedDayTasks.count
        )
        .padding(.bottom, 28)
    }
    
    private var dateStrip: some View {
        DateStripView(
            tasks: tasks,
            selectedDate: $selectedDate
        )
        .padding(.bottom, 28)
    }
    
    private var tasksHeader: some View {
        TasksHeader(
            selectedDate: selectedDate,
            isToday: isToday(selectedDate),
            onAddTask: {
                showAddTask = true
            }
        )
    }
    
    private var taskList: some View {
        LazyVStack(spacing: 12) {
            ForEach(selectedDayTasks) { task in
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
    }
    
    @ViewBuilder
    private var emptyState: some View {
        if selectedDayTasks.isEmpty {
            EmptyTaskView(
                isToday: isToday(selectedDate)
            )
        }
    }
    
    
    // MARK: - Helpers
    
    private func isToday(_ date: Date) -> Bool {
        calendar.isDateInToday(date)
    }
    
    private func toggleTask(_ task: TaskItem) {
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
