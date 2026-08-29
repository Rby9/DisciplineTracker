import SwiftUI

struct ProgressHeaderView: View {
    
    let progress: Double
    let completedTask: Int
    let totalTask: Int
    
    var body: some View {
        VStack(spacing: 12) {
            
            ZStack {
                Circle()
                    .stroke(
                        Color(hex: "2E2A4D"),
                        lineWidth: 10
                    )
                
                Circle()
                    .trim(
                        from: 0,
                        to: progress
                    )
                    .stroke(
                        Color(hex: "8B7CFF"),
                        style: StrokeStyle(
                            lineWidth: 10,
                            lineCap: .round
                        )
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(
                        .easeInOut,
                        value: progress
                    )
                VStack(spacing: 2) {
                    Text("\(Int(progress * 100))%")
                        .font(
                            .system(
                                size: 26,
                                weight: .bold
                            )
                        )
                        .foregroundStyle(.white)
                    
                    Text("Progress")
                        .font(.system(size: 12))
                        .foregroundStyle(
                            .white.opacity(0.55)
                        )
                }
            }
            .frame(width: 130, height: 130)
            
            Text("\(completedTask) of \(totalTask) completed")
                .font(
                    .system(size: 14,
                            weight: .medium
                    )
                )
                .foregroundStyle(.white.opacity(0.7)
                )
        }
    }
}
 
