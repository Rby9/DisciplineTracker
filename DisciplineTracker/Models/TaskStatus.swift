import SwiftUI

enum TaskStatus: String, CaseIterable, Identifiable {
    case pending = "Pending"
    case completed = "Completed"
    case skipped = "Skipped"

    var id: String { rawValue }
    var symbol: String {
        switch self {
        case .pending: return "circle"
        case .completed: return "checkmark.circle.fill"
        case .skipped: return "forward.end.circle.fill"
        }
    }
    var color: Color {
        switch self {
        case .pending: return .secondary
        case .completed: return AppTheme.accent
        case .skipped: return .orange
        }
    }
}
