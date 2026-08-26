import Foundation
import SwiftUI
import SwiftData

@Model
class TaskItem {
    var id: UUID
    var title: String
    var category: TaskCategory
    var startTime: Date
    var isCompleted: Bool
    var notes: String
    
    init(id: UUID = UUID(), title: String, category: TaskCategory, startTime: Date, isCompleted: Bool, notes: String) {
        self.id = id
        self.title = title
        self.category = category
        self.startTime = startTime
        self.isCompleted = isCompleted
        self.notes = notes
    }
}

enum TaskCategory : String, CaseIterable, Codable {
    case gym = "Gym"
    case food = "Food"
    case work = "Work"
    case sleep = "Sleep"
    case other = "Other"
    
    var color: Color {
        switch self {
        case .gym: return .red
        case .food: return .orange
        case .work: return .blue
        case .sleep: return .purple
        case .other: return .gray
        }
    }
}
