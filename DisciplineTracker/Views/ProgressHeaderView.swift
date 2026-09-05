import SwiftUI

struct ProgressHeaderView: View {

    // MARK: - Properties

    let progress: Double
    let completedTask: Int
    let totalTask: Int

    var reloadID: Int = 0

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
            progress: progress,
            reloadID: reloadID
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
