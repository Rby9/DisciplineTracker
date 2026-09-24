import Foundation
import SwiftData

enum GoalPeriod: String, CaseIterable, Codable {
    case weekly
    case monthly

    var title: LocalizedStringResource {
        switch self {
        case .weekly: "Weekly"
        case .monthly: "Monthly"
        }
    }
}

@Model
final class Goal {
    @Attribute(.unique) var id: UUID
    var title: String
    var periodRaw: String
    var categoryRaw: String?
    var targetCount: Int
    var startDate: Date
    var endDate: Date
    var createdAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        period: GoalPeriod,
        category: TaskCategory?,
        targetCount: Int,
        startDate: Date,
        endDate: Date,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.periodRaw = period.rawValue
        self.categoryRaw = category?.rawValue
        self.targetCount = targetCount
        self.startDate = startDate
        self.endDate = endDate
        self.createdAt = createdAt
    }

    var period: GoalPeriod {
        GoalPeriod(rawValue: periodRaw) ?? .weekly
    }

    var category: TaskCategory? {
        guard let categoryRaw else { return nil }
        return TaskCategory(rawValue: categoryRaw)
    }
}
