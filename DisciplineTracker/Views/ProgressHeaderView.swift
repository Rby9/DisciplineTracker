import SwiftUI

struct ProgressHeaderView: View {
    
    let progress: Double
    let completedTask: Int
    let totalTask: Int
    
    var body: some View {
        VStack(spacing: 12) {
            
            ProgressRing(
                progress: progress
            )
            
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
}
