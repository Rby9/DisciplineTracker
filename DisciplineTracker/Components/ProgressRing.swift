
import SwiftUI

struct ProgressRing: View {
    
    // MARK: - Properties
    
    let progress: Double
    
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            backgroundRing
            progressRing
            progressLabel
        }
        .frame(
            width: 130,
            height: 130
        )
    }
    
    
    // MARK: - View Components
    
    private var backgroundRing: some View {
        Circle()
            .stroke(
                Color(hex: "2E2A4D"),
                lineWidth: 10
            )
    }
    
    private var progressRing: some View {
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
    }
    
    private var progressLabel: some View {
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
}


#Preview {
    ProgressRing(progress: 0.66)
}
