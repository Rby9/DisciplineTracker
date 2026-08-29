import SwiftUI
import SwiftData

struct ContentView: View {
    
    @Query private var tasks: [TaskItem]
    
    @State private var showAddTask = false
    @State private var selectedDate = Date()
    
    private var calendar: Calendar {
        Calendar.current
    }
    
    // MARK: - Calendar Dates
    
    private var calendarDates: [Date] {
        let today = calendar.startOfDay(for: Date())
        
        return (-5...5).compactMap {
            calendar.date(
                byAdding: .day,
                value: $0,
                to: today
            )
        }
    }
    
    // MARK: - Progress
    
    private func progressForDate(_ date: Date) -> Double {
        let dayTasks = tasks.filter {
            calendar.isDate(
                $0.startTime,
                inSameDayAs: date
            )
        }
        
        guard !dayTasks.isEmpty else {
            return 0
        }
        
        let completed = dayTasks.filter {
            $0.isCompleted
        }.count
        
        return Double(completed) / Double(dayTasks.count)
    }
    
    // MARK: - Selected Day
    
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
                Color(hex: "0D0B16")
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        
                        // MARK: - Header
                        
                        DashboardHeader()
                        
                        // MARK: - Progress
                        
                        ProgressHeaderView(
                            progress: progress,
                            completedTask: completedTasks,
                            totalTask: selectedDayTasks.count
                        )
                        .padding(.bottom, 28)
                        
                        // MARK: - Date Strip
                        
                        DateStripView(
                            tasks: tasks,
                            selectedDate: $selectedDate
                        )
                        .padding(.bottom, 28)
                        
                        // MARK: - Tasks Header
                        
                        TasksHeader(
                            selectedDate: selectedDate,
                            isToday: isToday(selectedDate),
                            onAddTask: {
                                showAddTask = true
                            }
                        )
                        
                        // MARK: - Task Cards
                        
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
                        
                        // MARK: - Empty State
                        
                        if selectedDayTasks.isEmpty {
                            EmptyTaskView(
                                isToday: isToday(selectedDate)
                            )
                        }
                    }
                    .padding(.bottom, 30)
                }
            }
            .toolbar(
                .hidden,
                for: .navigationBar
            )
            .sheet(isPresented: $showAddTask) {
                AddTaskView()
            }
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
