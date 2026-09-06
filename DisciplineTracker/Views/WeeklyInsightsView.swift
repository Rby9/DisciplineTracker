import SwiftUI
import SwiftData
import Foundation

struct WeeklyInsightsView: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var tasks: [TaskItem]
    @Query private var entries: [JournalEntry]
    @State private var selectedDate: Date
    @State private var journalDay: InsightJournalDay?

    init(initialDate: Date) {
        _selectedDate = State(initialValue: initialDate)
    }

    private var calendar: Calendar { .current }
    private var firstDay: Date {
        let day = calendar.startOfDay(for: selectedDate)
        let weekday = calendar.component(.weekday, from: day)
        return calendar.date(byAdding: .day, value: -((weekday + 5) % 7), to: day) ?? day
    }
    private var days: [Date] {
        (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: firstDay) }
    }
    private var end: Date { calendar.date(byAdding: .day, value: 7, to: firstDay) ?? firstDay }
    private var weekTasks: [TaskItem] {
        tasks.filter { $0.startTime >= firstDay && $0.startTime < end }
    }
    private var completed: Int { weekTasks.filter { $0.isCompleted }.count }
    private var pending: Int { weekTasks.filter { $0.isPending }.count }
    private var skipped: Int { weekTasks.filter { $0.isSkipped }.count }
    private var progress: Double {
        weekTasks.isEmpty ? 0 : Double(completed) / Double(weekTasks.count)
    }
    private var hasJournal: Bool { days.contains { entry(for: $0) != nil } }

    var body: some View {
        NavigationStack {
            AppForm {
                weekNavigation
                overview
                dayBreakdown
                categoryBreakdown
                journalSection
                Section {
                    Text("These figures reflect the tasks currently scheduled for this week. Skipped tasks remain in Planned, but do not count as completed or pending. Moving or deleting a task updates these figures.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Weekly insights")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .sheet(item: $journalDay) { day in
                JournalView(initialDate: day.date)
            }
        }
    }

    private var weekNavigation: some View {
        Section {
            HStack(spacing: 12) {
                Button { moveWeek(-1) } label: {
                    Image(systemName: "chevron.left").frame(width: 36, height: 44)
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Previous week")
                VStack(spacing: 4) {
                    Text(firstDay, format: .dateTime.day().month(.abbreviated).year())
                    if let last = days.last {
                        Text("– " + last.formatted(.dateTime.day().month(.abbreviated).year()))
                    }
                }
                .font(.subheadline.weight(.semibold))
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
                Button { moveWeek(1) } label: {
                    Image(systemName: "chevron.right").frame(width: 36, height: 44)
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Next week")
            }
            if Date() < firstDay || Date() >= end {
                Button("Back to this week") { selectedDate = Date() }
            }
        }
    }

    private var overview: some View {
        Section("Your week") {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .firstTextBaseline) {
                    Text("\(Int((progress * 100).rounded()))%")
                        .font(.largeTitle.bold())
                        .monospacedDigit().foregroundStyle(AppTheme.accent)
                    Text("completed").foregroundStyle(.secondary)
                }
                ProgressView(value: progress).tint(AppTheme.accent)
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    metric("Planned", count: weekTasks.count, color: .primary)
                    metric("Completed", count: completed, color: AppTheme.accent)
                    metric("Pending", count: pending, color: .secondary)
                    metric("Skipped", count: skipped, color: .orange)
                }
                if weekTasks.isEmpty {
                    Text("No tasks planned for this week yet.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            .padding(.vertical, 8)
        }
    }

    private func metric(_ title: String, count: Int, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(count)").font(.title2.bold()).monospacedDigit().foregroundStyle(color)
            Text(title).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var dayBreakdown: some View {
        Section {
            ForEach(days, id: \.self) { day in
                let items = weekTasks.filter { calendar.isDate($0.startTime, inSameDayAs: day) }
                Button { journalDay = InsightJournalDay(date: day) } label: {
                    HStack(spacing: 14) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(day, format: .dateTime.weekday(.abbreviated))
                                .font(.subheadline.weight(.semibold))
                            Text(day, format: .dateTime.day().month(.abbreviated))
                                .font(.caption2).foregroundStyle(.secondary)
                        }
                        .frame(width: 62, alignment: .leading)
                        VStack(alignment: .leading, spacing: 6) {
                            completionBar(items)
                            Text(items.isEmpty ? "No tasks" : "\(items.filter { $0.isCompleted }.count)/\(items.count) completed")
                                .font(.caption).foregroundStyle(.secondary)
                        }
                        if let raw = entry(for: day)?.moodRaw, let mood = JournalMood(rawValue: raw) {
                            Text(mood.emoji).accessibilityLabel(mood.rawValue)
                        } else {
                            Image(systemName: "book.closed").foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                    .foregroundStyle(.primary)
                }
                .buttonStyle(.borderless)
            }
        } header: { Text("By day") } footer: { Text("Purple: completed · Orange: skipped · Gray: pending. Tap a day to open its journal.") }
    }

    private func completionBar(_ items: [TaskItem]) -> some View {
        let done = items.filter { $0.isCompleted }.count
        let skippedCount = items.filter { $0.isSkipped }.count
        let pendingCount = items.filter { $0.isPending }.count
        return GeometryReader { geometry in
            if items.isEmpty {
                Capsule().fill(AppTheme.border)
            } else {
                HStack(spacing: 0) {
                    Rectangle().fill(AppTheme.accent)
                        .frame(width: geometry.size.width * CGFloat(done) / CGFloat(items.count))
                    Rectangle().fill(.orange)
                        .frame(width: geometry.size.width * CGFloat(skippedCount) / CGFloat(items.count))
                    Rectangle().fill(AppTheme.border)
                        .frame(width: geometry.size.width * CGFloat(pendingCount) / CGFloat(items.count))
                }
                .clipShape(Capsule())
            }
        }
        .frame(height: 8)
        .accessibilityLabel("\(done) completed, \(skippedCount) skipped, \(pendingCount) pending")
    }

    private var categoryBreakdown: some View {
        Section("By category") {
            if weekTasks.isEmpty {
                Text("Your categories will appear when you plan tasks.")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            ForEach(TaskCategory.allCases, id: \.self) { category in
                let items = weekTasks.filter { $0.category == category }
                if !items.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(category.rawValue).foregroundStyle(category.color)
                            Spacer()
                            Text("\(items.filter { $0.isCompleted }.count)/\(items.count)")
                                .monospacedDigit().foregroundStyle(.secondary)
                        }
                        .font(.subheadline.weight(.medium))
                        completionBar(items)
                    }
                    .padding(.vertical, 5)
                }
            }
        }
    }

    private var journalSection: some View {
        Section("Journal this week") {
            if !hasJournal {
                Text("No journal entries yet. Tap a day above to write a few words or record your mood.")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            ForEach(days, id: \.self) { day in
                if let journal = entry(for: day) {
                    Button { journalDay = InsightJournalDay(date: day) } label: {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(day, format: .dateTime.weekday(.wide))
                                    .font(.subheadline.weight(.semibold))
                                Spacer()
                                if let raw = journal.moodRaw, let mood = JournalMood(rawValue: raw) {
                                    Text("\(mood.emoji) \(mood.rawValue)").font(.caption)
                                }
                            }
                            if !journal.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                Text(journal.note).font(.subheadline)
                                    .foregroundStyle(.secondary).lineLimit(3)
                            }
                        }
                        .padding(.vertical, 5).foregroundStyle(.primary)
                    }
                    .buttonStyle(.borderless)
                }
            }
        }
    }

    private func entry(for day: Date) -> JournalEntry? {
        entries.first { $0.dayKey == JournalEntry.key(for: day) }
    }

    private func moveWeek(_ direction: Int) {
        if let date = calendar.date(byAdding: .day, value: direction * 7, to: selectedDate) {
            selectedDate = date
        }
    }
}

private struct InsightJournalDay: Identifiable {
    let date: Date
    var id: String { JournalEntry.key(for: date) }
}
