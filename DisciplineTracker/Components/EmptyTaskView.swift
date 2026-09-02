import SwiftUI

struct EmptyTaskView: View {
    
    // MARK: - Properties
    
    let isToday: Bool
    
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 10) {
            icon
            
            title
            
            subtitle
        }
        .padding(.top, 60)
    }
    
    
    // MARK: - View Components
    
    private var icon: some View {
        Image(systemName: "checkmark.circle")
            .font(.system(size: 40))
            .foregroundStyle(
                Color(hex: "8B7CFF")
            )
    }
    
    private var title: some View {
        Text(
            isToday
                ? "No tasks today"
                : "No tasks"
        )
        .font(.headline)
        .foregroundStyle(.white)
    }
    
    private var subtitle: some View {
        Text("Tap + to add a task.")
            .font(.subheadline)
            .foregroundStyle(
                .white.opacity(0.55)
            )
    }
}


#Preview {
    EmptyTaskView(isToday: true)
}
