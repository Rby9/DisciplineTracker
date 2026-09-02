import SwiftUI

struct TasksHeader: View {
    
    // MARK: - Properties
    
    let selectedDate: Date
    let isToday: Bool
    let onAddTask: () -> Void
    
    
    // MARK: - Body
    
    var body: some View {
        HStack {
            titleSection
            
            Spacer()
            
            addButton
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
    }
    
    
    // MARK: - View Components
    
    private var titleSection: some View {
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
    }
    
    private var addButton: some View {
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
}


#Preview {
    TasksHeader(
        selectedDate: Date(),
        isToday: true,
        onAddTask: {}
    )
}
