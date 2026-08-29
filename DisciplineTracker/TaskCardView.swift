import SwiftUI

struct TaskCardView: View {
    
    let task: TaskItem
    let onToggle: () -> Void
    
    var body: some View {
        
        TimelineView(.periodic(from: .now, by: 30)) { context in
            
            HStack(spacing: 14) {
                
                Button {
                    onToggle()
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
                    .font(.system(size: 26))
                }
                .buttonStyle(.plain)
                
                VStack(
                    alignment: .leading,
                    spacing: 5
                ) {
                    
                    Text(task.title)
                        .font(
                            .system(
                                size: 16,
                                weight: .semibold
                            )
                        )
                        .foregroundStyle(.white)
                        .strikethrough(task.isCompleted)
                    
                    Text(statusText(at: context.date))
                        .font(.system(size: 13))
                        .foregroundStyle(statusColor(at: context.date))
                }
                
                Spacer()
                
                VStack(
                    alignment: .trailing,
                    spacing: 6
                ) {
                    
                    Text(
                        task.startTime,
                        style: .time
                    )
                    .font(
                        .system(
                            size: 13,
                            weight: .medium
                        )
                    )
                    .foregroundStyle(
                        .white.opacity(0.65)
                    )
                    
                    Text(task.category.rawValue)
                        .font(
                            .system(
                                size: 12,
                                weight: .semibold
                            )
                        )
                        .foregroundStyle(
                            task.category.color
                        )
                        .padding(
                            .horizontal,
                            10
                        )
                        .padding(
                            .vertical,
                            6
                        )
                        .background(
                            task.category.color.opacity(0.15)
                        )
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 10)
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
    }
    
    private func statusText(at date: Date) -> String {
        
        if task.isCompleted {
            return "Completed"
        }
        
        let secondsRemaining =
            task.startTime.timeIntervalSince(date)
        
        if secondsRemaining <= 0 {
            let overdue = formatTime(
                abs(secondsRemaining)
            )
            
            return "Overdue by \(overdue)"
        }
        
        return "Starts in \(formatTime(secondsRemaining))"
    }
    
    private func statusColor(at date: Date) -> Color {
        
        if task.isCompleted {
            return task.category.color
        }
        
        if task.startTime <= date {
            return .red.opacity(0.8)
        }
        
        return Color(hex: "8B7CFF")
    }
    
    private func formatTime(
        _ seconds: TimeInterval
    ) -> String {
        
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [
            .day,
            .hour,
            .minute
        ]
        formatter.unitsStyle = .abbreviated
        formatter.maximumUnitCount = 2
        formatter.zeroFormattingBehavior = .dropAll
        
        return formatter.string(
            from: seconds
        ) ?? "0m"
    }
}

#Preview {
    // Preview-ul îl lăsăm pentru mai târziu
}
