import SwiftUI

struct DateStripView: View {
    
    let tasks: [TaskItem]
    @Binding var selectedDate: Date
    
    private var calendar: Calendar {
        Calendar.current
    }
    
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
    
    var body: some View {
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
                        dateButton(date)
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
    }
    
    private func dateButton(_ date: Date) -> some View {
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
                
                let dayProgress = progressForDate(date)
                
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
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(
                                    Color.white.opacity(0.12)
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
    }
    
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
    
    private func isSelected(_ date: Date) -> Bool {
        calendar.isDate(
            date,
            inSameDayAs: selectedDate
        )
    }
}
