import SwiftUI

struct TasksHeader: View {
    
    let selectedDate: Date
    let isToday: Bool
    let onAddTask: () -> Void
    
    var body: some View {
        HStack {
            VStack(
                alignment: .leading,
                spacing: 4
            ) {
                Text(
                    isToday
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
                onAddTask()
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
    }
}
