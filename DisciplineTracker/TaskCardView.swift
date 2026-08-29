import SwiftUI

struct TaskCardView: View {
    
    let task: TaskItem
    let onToggle: () -> Void
    
    var body: some View {
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
                spacing: 4
            ) {
                Text(task.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white)
                    .strikethrough(task.isCompleted)
                
                Text(
                    task.startTime,
                    style: .time
                )
                .font(.system(size: 13))
                .foregroundStyle(
                    .white.opacity(0.55)
                )
            }
            
            Spacer()
            
            Text(task.category.rawValue)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(task.category.color)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    task.category.color.opacity(0.15)
                )
                .clipShape(
                    Capsule()
                )
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

#Preview {
    // Preview-ul îl lăsăm pentru mai târziu
}
