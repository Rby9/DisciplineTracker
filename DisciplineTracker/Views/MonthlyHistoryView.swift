import SwiftUI
import SwiftData

struct MonthlyHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \TaskItem.startTime) private var tasks: [TaskItem]
    @Query(sort: \JournalEntry.date) private var journalEntries: [JournalEntry]

    @State private var displayedMonth: Date
    @State private var selectedDay: HistoryDay?

    private let calendar: Calendar
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)

    init(initialDate: Date) {
        var calendar = Calendar.current
        calendar.firstWeekday = 2
        self.calendar = calendar
        let components = calendar.dateComponents([.year, .month], from: initialDate)
        _displayedMonth = State(initialValue: calendar.date(from: components) ?? initialDate)
    }

    private var days: [HistoryDay] {
        guard
            let interval = calendar.dateInterval(of: .month, for: displayedMonth),
            let dayRange = calendar.range(of: .day, in: .month, for: displayedMonth)
        else { return [] }

        let weekday = calendar.component(.weekday, from: interval.start)
        let leadingSpaces = (weekday - calendar.firstWeekday + 7) % 7
        var result = (0..<leadingSpaces).map { HistoryDay.placeholder($0) }

        result += dayRange.compactMap { day in
            guard let date = calendar.date(byAdding: .day, value: day - 1, to: interval.start) else {
                return nil
            }
            let dayTasks = tasks.filter { calendar.isDate($0.startTime, inSameDayAs: date) }
            let journal = journalEntries.first { $0.dayKey == JournalEntry.key(for: date) }
            return HistoryDay(date: date, tasks: dayTasks, journal: journal)
        }
        return result
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    monthHeader
                    weekdayHeader

                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(days) { day in
                            if day.date == nil {
                                Color.clear.frame(height: 54)
                            } else {
                                HistoryDayCell(day: day) { selectedDay = day }
                            }
                        }
                    }

                    legend
                    monthSummary
                }
                .padding(18)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Monthly history")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(item: $selectedDay) { day in
                HistoryDayDetail(day: day)
                    .presentationDetents([.medium, .large])
                    .presentationDragIndicator(.visible)
            }
        }
        .preferredColorScheme(.dark)
    }

    private var monthHeader: some View {
        HStack {
            monthButton("chevron.left", label: "Previous month") { moveMonth(-1) }
            Spacer()
            VStack(spacing: 3) {
                Text(displayedMonth, format: .dateTime.month(.wide).year())
                    .font(.title3.bold())
                if !calendar.isDate(displayedMonth, equalTo: Date(), toGranularity: .month) {
                    Button("Current month") { displayedMonth = startOfMonth(Date()) }
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.accent)
                }
            }
            Spacer()
            monthButton("chevron.right", label: "Next month") { moveMonth(1) }
        }
    }

    private var weekdayHeader: some View {
        let symbols = calendar.veryShortStandaloneWeekdaySymbols
        let ordered = Array(symbols[1...]) + [symbols[0]]
        return HStack(spacing: 6) {
            ForEach(ordered, id: \.self) { symbol in
                Text(symbol.uppercased())
                    .font(.caption2.bold())
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var legend: some View {
        HStack(spacing: 12) {
            HistoryLegendItem(color: .green, title: "Complete")
            HistoryLegendItem(color: AppTheme.accent, title: "Partial")
            HistoryLegendItem(color: .red, title: "Missed")
            HistoryLegendItem(color: .gray, title: "Free")
        }
        .font(.caption2)
        .frame(maxWidth: .infinity)
    }

    private var monthSummary: some View {
        let realDays = days.filter { $0.date != nil }
        let completed = realDays.filter { $0.state == .complete }.count
        let completedTasks = realDays.flatMap(\.tasks).filter(\.isCompleted).count
        return HStack(spacing: 12) {
            summaryValue("\(completed)", title: "Complete days", icon: "checkmark.circle.fill")
            summaryValue("\(completedTasks)", title: "Tasks completed", icon: "checkmark.square.fill")
        }
    }

    private func summaryValue(_ value: String, title: LocalizedStringKey, icon: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon).foregroundStyle(AppTheme.accent)
            Text(value).font(.title2.bold())
            Text(title).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 16))
        .overlay { RoundedRectangle(cornerRadius: 16).stroke(AppTheme.border) }
    }

    private func monthButton(_ icon: String, label: LocalizedStringKey, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon).frame(width: 44, height: 44)
                .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 13))
        }
        .buttonStyle(.plain)
        .foregroundStyle(AppTheme.accent)
        .accessibilityLabel(Text(label))
    }

    private func moveMonth(_ offset: Int) {
        displayedMonth = calendar.date(byAdding: .month, value: offset, to: displayedMonth) ?? displayedMonth
    }

    private func startOfMonth(_ date: Date) -> Date {
        calendar.date(from: calendar.dateComponents([.year, .month], from: date)) ?? date
    }
}

private struct HistoryDay: Identifiable {
    let id: String
    let date: Date?
    let tasks: [TaskItem]
    let journal: JournalEntry?

    init(date: Date, tasks: [TaskItem], journal: JournalEntry?) {
        id = JournalEntry.key(for: date)
        self.date = date
        self.tasks = tasks
        self.journal = journal
    }

    static func placeholder(_ index: Int) -> HistoryDay {
        HistoryDay(id: "placeholder-\(index)", date: nil, tasks: [], journal: nil)
    }

    private init(id: String, date: Date?, tasks: [TaskItem], journal: JournalEntry?) {
        self.id = id
        self.date = date
        self.tasks = tasks
        self.journal = journal
    }

    var state: HistoryDayState {
        guard let date else { return .free }
        let relevant = tasks.filter { !$0.isSkipped }
        guard !relevant.isEmpty else { return .free }
        let completed = relevant.filter(\.isCompleted).count
        if completed == relevant.count { return .complete }
        if completed > 0 { return .partial }
        if Calendar.current.startOfDay(for: date) < Calendar.current.startOfDay(for: Date()) { return .missed }
        return .upcoming
    }
}

private enum HistoryDayState {
    case complete, partial, missed, free, upcoming

    var color: Color {
        switch self {
        case .complete: .green
        case .partial: AppTheme.accent
        case .missed: .red
        case .free: .gray
        case .upcoming: .white
        }
    }
}

private struct HistoryDayCell: View {
    let day: HistoryDay
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Text(day.date ?? Date(), format: .dateTime.day())
                    .font(.subheadline.weight(.semibold))
                HStack(spacing: 3) {
                    Circle().fill(day.state.color).frame(width: 7, height: 7)
                    if day.journal != nil {
                        Image(systemName: "book.closed.fill").font(.system(size: 7))
                    }
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, minHeight: 54)
            .background(day.state.color.opacity(day.state == .upcoming ? 0.06 : 0.14), in: RoundedRectangle(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Calendar.current.isDateInToday(day.date ?? .distantPast) ? AppTheme.accent : AppTheme.border, lineWidth: Calendar.current.isDateInToday(day.date ?? .distantPast) ? 2 : 1)
            }
        }
        .buttonStyle(.plain)
    }
}

private struct HistoryLegendItem: View {
    let color: Color
    let title: LocalizedStringKey

    var body: some View {
        HStack(spacing: 4) {
            Circle().fill(color).frame(width: 7, height: 7)
            Text(title).foregroundStyle(.secondary)
        }
    }
}

private struct HistoryDayDetail: View {
    @Environment(\.dismiss) private var dismiss
    let day: HistoryDay
    @State private var showJournal = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    if day.tasks.isEmpty {
                        ContentUnavailableView("Free day", systemImage: "sparkles", description: Text("No tasks were planned for this day."))
                    } else {
                        ForEach(day.tasks) { task in
                            NavigationLink {
                                TaskDetailView(task: task)
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: task.isCompleted ? "checkmark.circle.fill" : task.isSkipped ? "forward.circle.fill" : "circle")
                                        .foregroundStyle(task.isCompleted ? .green : task.category.color)
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(task.title).font(.headline).foregroundStyle(.white)
                                        Text(task.startTime, format: .dateTime.hour().minute())
                                            .font(.caption).foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary)
                                }
                                .padding(14)
                                .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 15))
                                .overlay { RoundedRectangle(cornerRadius: 15).stroke(AppTheme.border) }
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Button { showJournal = true } label: {
                        HStack(spacing: 12) {
                            Image(systemName: "book.closed.fill").foregroundStyle(AppTheme.accent)
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Journal").font(.headline)
                                Text(journalPreview).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                            }
                            Spacer()
                            Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary)
                        }
                        .padding(14)
                        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 15))
                        .overlay { RoundedRectangle(cornerRadius: 15).stroke(AppTheme.border) }
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.white)
                }
                .padding(18)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle(day.date?.formatted(.dateTime.weekday(.wide).day().month(.wide)) ?? "Day")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } } }
            .sheet(isPresented: $showJournal) {
                JournalView(initialDate: day.date ?? Date())
            }
        }
        .preferredColorScheme(.dark)
    }

    private var journalPreview: String {
        let note = day.journal?.note.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return note.isEmpty ? String(localized: "Write or review this day's journal") : note
    }
}
