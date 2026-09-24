import SwiftUI
import SwiftData

struct TaskSearchView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \TaskItem.startTime) private var tasks: [TaskItem]
    @State private var search = ""
    @State private var category: TaskCategory?
    @State private var status: TaskStatus?
    @State private var period = SearchPeriod.all
    @State private var newestFirst = false

    private enum SearchPeriod: String, CaseIterable {
        case all = "Any date", today = "Today", week = "This week", future = "Upcoming", past = "Past"
    }

    private var results: [TaskItem] {
        let query = search.trimmingCharacters(in: .whitespacesAndNewlines)
        let now = Date()
        let calendar = Calendar.current
        let filtered = tasks.filter { task in
            guard category == nil || task.category == category,
                  status == nil || task.status == status else { return false }
            if !query.isEmpty && !task.title.localizedStandardContains(query) && !task.notes.localizedStandardContains(query) {
                return false
            }
            switch period {
            case .all: return true
            case .today: return calendar.isDateInToday(task.startTime)
            case .week:
                let today = calendar.startOfDay(for: now)
                let weekday = calendar.component(.weekday, from: today)
                let monday = calendar.date(byAdding: .day, value: -((weekday + 5) % 7), to: today) ?? today
                let end = calendar.date(byAdding: .day, value: 7, to: monday) ?? monday
                return task.startTime >= monday && task.startTime < end
            case .future: return task.startTime >= now
            case .past: return task.startTime < now
            }
        }
        return filtered.sorted {
            if $0.startTime == $1.startTime { return $0.id.uuidString < $1.id.uuidString }
            return newestFirst ? $0.startTime > $1.startTime : $0.startTime < $1.startTime
        }
    }

    var body: some View {
        NavigationStack {
            AppForm {
                Section("Filters") {
                    Picker("Category", selection: $category) {
                        Text("All categories").tag(nil as TaskCategory?)
                        ForEach(TaskCategory.allCases, id: \.self) { item in
                            Text(LocalizedStringKey(item.rawValue)).tag(Optional(item))
                        }
                    }
                    Picker("Status", selection: $status) {
                        Text("All statuses").tag(nil as TaskStatus?)
                        ForEach(TaskStatus.allCases) { item in
                            Text(LocalizedStringKey(item.rawValue)).tag(Optional(item))
                        }
                    }
                    Picker("Period", selection: $period) {
                        ForEach(SearchPeriod.allCases, id: \.self) { item in
                            Text(LocalizedStringKey(item.rawValue)).tag(item)
                        }
                    }
                    Toggle("Newest first", isOn: $newestFirst)
                    if category != nil || status != nil || period != .all || !search.isEmpty || newestFirst {
                        Button("Reset filters") {
                            category = nil; status = nil; period = .all
                            search = ""; newestFirst = false
                        }
                    }
                }
                let matches = results
                Section {
                    if matches.isEmpty {
                        ContentUnavailableView("No matching activities", systemImage: "magnifyingglass",
                                               description: Text("Try another title, note or filter."))
                    } else {
                        ForEach(matches) { task in
                            NavigationLink {
                                TaskDetailView(task: task)
                            } label: {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(task.title).font(.headline)
                                    HStack {
                                        Text(LocalizedStringKey(task.category.rawValue))
                                            .foregroundStyle(task.category.color)
                                        Spacer()
                                        Label(LocalizedStringKey(task.status.rawValue), systemImage: task.status.symbol)
                                            .foregroundStyle(task.status.color)
                                    }
                                    .font(.caption)
                                    Text(task.startTime, format: .dateTime.day().month(.abbreviated).year().hour().minute())
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                } header: {
                    Text("Results: \(matches.count)")
                }
            }
            .searchable(text: $search, prompt: "Search titles and notes")
            .navigationTitle("Search activities")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
            }
        }
    }
}
