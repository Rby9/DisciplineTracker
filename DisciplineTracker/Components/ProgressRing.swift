import SwiftUI

struct ProgressRing: View {

    // MARK: - Environment

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    // MARK: - Properties

    let progress: Double
    var reloadID: Int = 0

    @State private var displayedProgress: Double = 0
    @State private var targetProgress: Double = 0
    @State private var isPreparingReload = false

    private var clampedProgress: Double {
        min(max(progress, 0), 1)
    }

    // MARK: - Body

    var body: some View {
        AnimatedProgressRing(
            progress: displayedProgress
        )
        .frame(width: 130, height: 130)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Progress")
        .accessibilityValue(
            "\(Int((clampedProgress * 100).rounded())) percent"
        )
        .task(id: reloadID) {
            await reloadProgress()
        }
        .onChange(of: progress) { _, newValue in
            targetProgress = min(max(newValue, 0), 1)

            guard !isPreparingReload else {
                return
            }

            animateToTarget(duration: 0.45)
        }
    }

    // MARK: - Reload

    @MainActor
    private func reloadProgress() async {
        targetProgress = clampedProgress

        guard !reduceMotion else {
            isPreparingReload = false
            setProgressImmediately(targetProgress)
            return
        }

        isPreparingReload = true
        setProgressImmediately(0)

        do {
            try await Task.sleep(for: .milliseconds(60))
        } catch {
            return
        }

        guard !Task.isCancelled else {
            return
        }

        isPreparingReload = false
        animateToTarget(duration: 0.9)
    }

    // MARK: - Animation Helpers

    private func animateToTarget(duration: Double) {
        guard !reduceMotion else {
            setProgressImmediately(targetProgress)
            return
        }

        withAnimation(.easeInOut(duration: duration)) {
            displayedProgress = targetProgress
        }
    }

    private func setProgressImmediately(_ value: Double) {
        var transaction = Transaction()
        transaction.disablesAnimations = true

        withTransaction(transaction) {
            displayedProgress = value
        }
    }
}


// MARK: - Animated Ring Content

private struct AnimatedProgressRing: View, Animatable {

    var progress: Double

    var animatableData: Double {
        get { progress }
        set { progress = newValue }
    }

    private var safeProgress: Double {
        min(max(progress, 0), 1)
    }

    private var percentage: Int {
        Int((safeProgress * 100).rounded())
    }

    var body: some View {
        ZStack {
            backgroundRing
            foregroundRing
            progressLabel
        }
    }

    private var backgroundRing: some View {
        Circle()
            .stroke(
                Color(hex: "2E2A4D"),
                lineWidth: 10
            )
    }

    private var foregroundRing: some View {
        Circle()
            .trim(from: 0, to: safeProgress)
            .stroke(
                Color(hex: "8B7CFF"),
                style: StrokeStyle(
                    lineWidth: 10,
                    lineCap: .round
                )
            )
            .rotationEffect(.degrees(-90))
    }

    private var progressLabel: some View {
        VStack(spacing: 2) {
            Text("\(percentage)%")
                .font(
                    .system(
                        size: 26,
                        weight: .bold
                    )
                )
                .monospacedDigit()
                .foregroundStyle(.white)

            Text("Progress")
                .font(.system(size: 12))
                .foregroundStyle(
                    .white.opacity(0.55)
                )
        }
    }
}
