import Foundation

struct TaskItem: Identifiable {
    let id: UUID
    var title: String
    var category: TaskCategory
    var startTime: Date
    var isCompleted: Bool
    var notes: String
}

enum TaskCategory : String, CaseIterable {
    case gym = "Gym"
    case food = "Food"
    case work = "Work"
    case sleep = "Sleep"
    case other = "Other"
}
