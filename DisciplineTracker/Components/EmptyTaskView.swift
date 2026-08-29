import SwiftUI

struct EmptyTaskView: View {
    
    let isToday: Bool
    
    var body: some View {
        VStack(spacing: 10) {
            Image(
                systemName: "checkmark.circle"
            )
            .font(.system(size: 40))
            .foregroundStyle(
                Color(hex: "8B7CFF")
            )
            
            Text(
                isToday
                    ? "No tasks today"
                    : "No tasks"
            )
            .font(.headline)
            .foregroundStyle(.white)
            
            Text("Tap + to add a task.")
                .font(.subheadline)
                .foregroundStyle(
                    .white.opacity(0.55)
                )
        }
        .padding(.top, 60)
    }
}
