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
    
    // MARK: - Progress For Date
    
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
    
    // MARK: - Selected Day Tasks
    
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
                        
                        HStack {
                            Text("DisciplineTracker")
                                .font(
                                    .system(
                                        size: 24,
                                        weight: .bold
                                    )
                                )
                                .foregroundStyle(.white)
                            
                            Spacer()
                            
                            Button {
                                // Profile - later
                            } label: {
                                Image(systemName: "person.fill")
                                    .font(
                                        .system(
                                            size: 15,
                                            weight: .semibold
                                        )
                                    )
                                    .foregroundStyle(.white)
                                    .frame(
                                        width: 38,
                                        height: 38
                                    )
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
                            totalTask: selectedDayTasks.count
                        )
                        .padding(.bottom, 28)
                        
                        // MARK: - Date Strip
                        
                        ScrollViewReader { proxy in
                            ScrollView(
                                .horizontal,
                                showsIndicators: false
                            ) {
                                HStack(spacing: 8) {
                                    ForEach(
                                        calendarDates,
                                        id: \.self
                                    ) { date in
                                        
                                        Button {
                                            withAnimation(
                                                .spring(
                                                    response: 0.35,
                                                    dampingFraction: 0.8
                                                )
                                            ) {
                                                selectedDate = date
                                            }
                                        } label: {
                                            
                                            VStack(spacing: 4) {
                                                
                                                Text(
                                                    date,
                                                    format: .dateTime
                                                        .weekday(.abbreviated)
                                                )
                                                .font(
                                                    .system(
                                                        size: 11,
                                                        weight: .semibold
                                                    )
                                                )
                                                
                                                Text(
                                                    date,
                                                    format: .dateTime.day()
                                                )
                                                .font(
                                                    .system(
                                                        size: 18,
                                                        weight: .bold
                                                    )
                                                )
                                                
                                                let dayProgress =
                                                    progressForDate(date)
                                                
                                                if dayProgress > 0 {
                                                    
                                                    Text(
                                                        "\(Int(dayProgress * 100))%"
                                                    )
                                                    .font(
                                                        .system(
                                                            size: 9,
                                                            weight: .bold
                                                        )
                                                    )
                                                    .foregroundStyle(
                                                        isSelected(date)
                                                            ? .white
                                                            : Color(hex: "8B7CFF")
                                                    )
                                                    
                                                    GeometryReader { geometry in
                                                        ZStack(
                                                            alignment: .leading
                                                        ) {
                                                            
                                                            Capsule()
                                                                .fill(
                                                                    Color.white
                                                                        .opacity(0.12)
                                                                )
                                                            
                                                            Capsule()
                                                                .fill(
                                                                    Color(hex: "8B7CFF")
                                                                )
                                                                .frame(
                                                                    width:
                                                                        geometry.size.width
                                                                        * dayProgress
                                                                )
                                                        }
                                                    }
                                                    .frame(
                                                        width: 34,
                                                        height: 3
                                                    )
                                                    
                                                } else {
                                                    
                                                    Text("—")
                                                        .font(
                                                            .system(
                                                                size: 9,
                                                                weight: .bold
                                                            )
                                                        )
                                                        .foregroundStyle(
                                                            .white.opacity(0.3)
                                                        )
                                                        .frame(height: 8)
                                                }
                                            }
                                            .foregroundStyle(
                                                isSelected(date)
                                                    ? .white
                                                    : .white.opacity(0.55)
                                            )
                                            .frame(
                                                width: 52,
                                                height: 74
                                            )
                                            .background(
                                                isSelected(date)
                                                    ? Color(hex: "8B7CFF")
                                                    : Color(hex: "161426")
                                            )
                                            .clipShape(
                                                RoundedRectangle(
                                                    cornerRadius: 14
                                                )
                                            )
                                            .overlay {
                                                RoundedRectangle(
                                                    cornerRadius: 14
                                                )
                                                .stroke(
                                                    isSelected(date)
                                                        ? Color(hex: "A99EFF")
                                                        : Color(hex: "2E2A4D"),
                                                    lineWidth: 1.5
                                                )
                                            }
                                        }
                                        .buttonStyle(.plain)
                                        .id(date)
                                        .scrollTransition(
                                            .interactive,
                                            axis: .horizontal
                                        ) { content, phase in
                                            
                                            content
                                                .opacity(
                                                    phase.isIdentity
                                                        ? 1.0
                                                        : 0.35
                                                )
                                                .scaleEffect(
                                                    phase.isIdentity
                                                        ? 1.0
                                                        : 0.78
                                                )
                                                .rotation3DEffect(
                                                    .degrees(
                                                        phase.value * -20
                                                    ),
                                                    axis: (
                                                        x: 0,
                                                        y: 1,
                                                        z: 0
                                                    )
                                                )
                                                .offset(
                                                    y: phase.isIdentity
                                                        ? 0
                                                        : 8
                                                )
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                            .onAppear {
                                let yesterday = calendar.date(
                                    byAdding: .day,
                                    value: -1,
                                    to: calendar.startOfDay(
                                        for: Date()
                                    )
                                )!
                                
                                DispatchQueue.main.async {
                                    proxy.scrollTo(
                                        yesterday,
                                        anchor: .leading
                                    )
                                }
                            }
                        }
                        .padding(.bottom, 28)
                        
                        // MARK: - Tasks Header
                        
                        HStack {
                            VStack(
                                alignment: .leading,
                                spacing: 4
                            ) {
                                Text(
                                    isToday(selectedDate)
                                        ? "Today's Tasks"
                                        : "Tasks"
                                )
                                .font(
                                    .system(
                                        size: 22,
                                        weight: .bold
                                    )
                                )
                                .foregroundStyle(.white)
                                
                                Text(
                                    selectedDate,
                                    format: .dateTime
                                        .weekday(.wide)
                                        .month(.wide)
                                        .day()
                                )
                                .font(.system(size: 13))
                                .foregroundStyle(
                                    .white.opacity(0.5)
                                )
                            }
                            
                            Spacer()
                            
                            Button {
                                showAddTask = true
                            } label: {
                                Image(systemName: "plus")
                                    .font(
                                        .system(
                                            size: 16,
                                            weight: .bold
                                        )
                                    )
                                    .foregroundStyle(.white)
                                    .frame(
                                        width: 36,
                                        height: 36
                                    )
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
                            VStack(spacing: 10) {
                                Image(
                                    systemName: "checkmark.circle"
                                )
                                .font(.system(size: 40))
                                .foregroundStyle(
                                    Color(hex: "8B7CFF")
                                )
                                
                                Text(
                                    isToday(selectedDate)
                                        ? "No tasks today"
                                        : "No tasks"
                                )
                                .font(.headline)
                                .foregroundStyle(.white)
                                
                                Text(
                                    "Tap + to add a task."
                                )
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
    
    private func isSelected(_ date: Date) -> Bool {
        calendar.isDate(
            date,
            inSameDayAs: selectedDate
        )
    }
    
    private func isToday(_ date: Date) -> Bool {
        calendar.isDateInToday(date)
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

// MARK: - Preview

#Preview {
    ContentView()
}

// MARK: - Color Extension

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
