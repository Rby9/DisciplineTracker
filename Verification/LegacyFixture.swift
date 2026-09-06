import Foundation
import SwiftData

@main
struct LegacyFixture {
    @MainActor static func main() throws {
        let url = URL(fileURLWithPath: CommandLine.arguments[1])
        let configuration = ModelConfiguration(url: url)
        let container = try ModelContainer(for: TaskItem.self, TaskSeries.self, JournalEntry.self,
                                           configurations: configuration)
        let context = container.mainContext
        let date = Date(timeIntervalSince1970: 1_789_200_000)
        context.insert(TaskItem(title: "Legacy pending", category: .work,
                                startTime: date, isCompleted: false, notes: "Keep my notes"))
        context.insert(TaskItem(title: "Legacy completed", category: .gym,
                                startTime: date, isCompleted: true, notes: ""))
        context.insert(TaskSeries(title: "Legacy routine", category: .food, notes: "",
                                  startDate: date, endDate: date, hour: 12, minute: 0,
                                  weekdays: [2, 4, 6]))
        context.insert(JournalEntry(date: date, note: "Keep my journal", moodRaw: "Good"))
        try context.save()
        print("PASS: legacy fixture created")
    }
}
