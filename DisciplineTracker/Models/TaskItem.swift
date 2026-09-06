import Foundation
import SwiftUI
import SwiftData

@Model
class TaskItem {

    // MARK: - Properties

    var id: UUID
    var title: String
    var category: TaskCategory
    var startTime: Date
    var isCompleted: Bool
    var notes: String

    // MARK: - Recurrence

    var seriesID: UUID? = nil
    var originalScheduledDate: Date? = nil

    // MARK: - Initialization

    init(
        id: UUID = UUID(),
        title: String,
        category: TaskCategory,
        startTime: Date,
        isCompleted: Bool,
        notes: String,
        seriesID: UUID? = nil,
        originalScheduledDate: Date? = nil
    ) {
        self.id = id
        self.title = title
        self.category = category
        self.startTime = startTime
        self.isCompleted = isCompleted
        self.notes = notes
        self.seriesID = seriesID
        self.originalScheduledDate = originalScheduledDate
    }
}


// MARK: - Task Category

enum TaskCategory: String, CaseIterable, Codable {

    case gym = "Gym"
    case food = "Food"
    case work = "Work"
    case sleep = "Sleep"
    case other = "Other"

    var color: Color {
        switch self {
        case .gym:
            return .red
        case .food:
            return .orange
        case .work:
            return .blue
        case .sleep:
            return .purple
        case .other:
            return .gray
        }
    }
}
