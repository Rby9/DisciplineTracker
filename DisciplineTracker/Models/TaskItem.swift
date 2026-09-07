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

    // Optional storage lets existing tasks migrate as Pending/Completed.
    var skipped: Bool? = nil

    var status: TaskStatus {
        isCompleted ? .completed : (skipped == true ? .skipped : .pending)
    }

    var isSkipped: Bool { status == .skipped }
    var isPending: Bool { status == .pending }

    func setStatus(_ newStatus: TaskStatus) {
        isCompleted = newStatus == .completed
        skipped = newStatus == .skipped
    }

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
    case medication = "Medication"
    
    case study = "Study"
    case personal = "Personal"
    case household = "Household"
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

            case .medication:
                return .teal

            case .study:
                return .indigo

            case .personal:
                return .pink

            case .household:
                return .green
                
            case .other:
                return .gray
        }
    }
}
