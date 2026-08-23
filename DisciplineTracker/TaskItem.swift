import Foundation
import SwiftUI

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
