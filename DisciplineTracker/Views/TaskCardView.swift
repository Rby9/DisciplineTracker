import SwiftUI
import Foundation

struct TaskCardView: View {

    // MARK: - Environment

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    // MARK: - Properties

    let task: TaskItem
    let onToggle: () -> Void

    // MARK: - Status Type

    private enum StatusKind: Hashable {
        case upcoming
        case overdue
        case completed
    }

    // MARK: - Body

    var body: some View {
        TimelineView(.periodic(from: .now, by: 30)) { context in
            HStack(spacing: 14) {
                completionButton

                titleSection(at: context.date)

                Spacer()

                timeAndCategory
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 10)
            .background(
                Color(hex: "161426")
            )
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        Color(hex: "2E2A4D"),
                        lineWidth: 2
                    )
            }
            .clipShape(
                RoundedRectangle(cornerRadius: 16)
            )
            .scrollTransition(
                .interactive,
                axis: .vertical
            ) { content, phase in
                content
                    .opacity(
                        phase.isIdentity ? 1 : 0.45
                    )
                    .scaleEffect(
                        phase.isIdentity ? 1 : 0.90
                    )
                    .blur(
                        radius: phase.isIdentity ? 0 : 2.5
                    )
                    .offset(
                        y: phase.isIdentity
                            ? 0
                            : phase.value * 18
                    )
                    .rotation3DEffect(
                        .degrees(phase.value * -5),
                        axis: (x: 1, y: 0, z: 0)
                    )
            }
        }
    }

    // MARK: - Completion Button

    private var completionButton: some View {
        Button {
            onToggle()
        } label: {
            Image(
                systemName: task.isCompleted
                    ? "checkmark.circle.fill"
                    : "circle"
            )
            .foregroundStyle(
                task.isCompleted
                    ? Color(hex: "8B7CFF")
                    : .white.opacity(0.6)
            )
            .font(.system(size: 26))
            .symbolEffect(
                .bounce,
                value: task.isCompleted
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Title Section

    private func titleSection(at date: Date) -> some View {
        VStack(
            alignment: .leading,
            spacing: 5
        ) {
            Text(task.title)
                .font(
                    .system(
                        size: 16,
                        weight: .semibold
                    )
                )
                .foregroundStyle(.white)
                .strikethrough(task.isCompleted)

            animatedStatus(at: date)
        }
    }

    // MARK: - Animated Status

    private func animatedStatus(at date: Date) -> some View {
        let text = statusText(at: date)
        let kind = statusKind(at: date)

        return ZStack(alignment: .leading) {
            Text(text)
                .font(.system(size: 13))
                .monospacedDigit()
                .foregroundStyle(statusColor(at: date))
                .contentTransition(
                    reduceMotion
                        ? .opacity
                        : .numericText()
                )
                .animation(
                    .easeInOut(duration: 0.3),
                    value: text
                )
                .id(kind)
                .transition(statusTransition)
        }
        .animation(
            reduceMotion
                ? .easeInOut(duration: 0.2)
                : .spring(
                    response: 0.38,
                    dampingFraction: 0.85
                ),
            value: kind
        )
    }

    private var statusTransition: AnyTransition {
        if reduceMotion {
            return .opacity
        }

        return .asymmetric(
            insertion: .opacity.combined(
                with: .offset(y: 7)
            ),
            removal: .opacity.combined(
                with: .offset(y: -7)
            )
        )
    }

    // MARK: - Time And Category

    private var timeAndCategory: some View {
        VStack(
            alignment: .trailing,
            spacing: 6
        ) {
            Text(task.startTime, style: .time)
                .font(
                    .system(
                        size: 13,
                        weight: .medium
                    )
                )
                .foregroundStyle(
                    .white.opacity(0.65)
                )

            Text(task.category.rawValue)
                .font(
                    .system(
                        size: 12,
                        weight: .semibold
                    )
                )
                .foregroundStyle(task.category.color)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    task.category.color.opacity(0.15)
                )
                .clipShape(Capsule())
        }
    }

    // MARK: - Status

    private func statusKind(at date: Date) -> StatusKind {
        if task.isCompleted {
            return .completed
        }

        if task.startTime <= date {
            return .overdue
        }

        return .upcoming
    }

    private func statusText(at date: Date) -> String {
        if task.isCompleted {
            return "Completed"
        }

        let secondsRemaining =
            task.startTime.timeIntervalSince(date)

        if secondsRemaining <= 0 {
            let overdue = formatTime(
                abs(secondsRemaining)
            )

            return "Overdue by \(overdue)"
        }

        return "Starts in \(formatTime(secondsRemaining))"
    }

    private func statusColor(at date: Date) -> Color {
        if task.isCompleted {
            return task.category.color
        }

        if task.startTime <= date {
            return .red.opacity(0.8)
        }

        return Color(hex: "8B7CFF")
    }

    // MARK: - Helpers

    private func formatTime(_ seconds: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.day, .hour, .minute]
        formatter.unitsStyle = .abbreviated
        formatter.maximumUnitCount = 2
        formatter.zeroFormattingBehavior = .dropAll

        return formatter.string(from: seconds) ?? "0m"
    }
}
