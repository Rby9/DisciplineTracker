import SwiftUI

struct ProgressHeaderView: View {
    
    // MARK: - Properties
    
    let progress: Double
    let completedTask: Int
    let totalTask: Int
    
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 12) {
            progressRing
            
            progressText
        }
    }
    
    
    // MARK: - View Components
    
    private var progressRing: some View {
        ProgressRing(
            progress: progress
        )
    }
    
    private var progressText: some View {
        Text(
            "\(completedTask) of \(totalTask) completed"
        )
        .font(
            .system(
                size: 14,
                weight: .medium
            )
        )
        .foregroundStyle(
            .white.opacity(0.7)
        )
    }
}


#Preview {
    ProgressHeaderView(
        progress: 0.66,
        completedTask: 2,
        totalTask: 3
    )
}
