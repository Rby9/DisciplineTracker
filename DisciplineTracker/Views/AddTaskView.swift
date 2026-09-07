import SwiftUI
import SwiftData
import Foundation

struct AddTaskView: View {

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // MARK: - Task Properties

    @State private var title = ""
    @State private var category: TaskCategory = .other
    @State private var startTime: Date
    @State private var notes = ""

    // MARK: - Recurrence Properties

    @State private var repeatOption: RepeatOption = .never
    @State private var duration: RoutineDuration = .threeMonths
    @State private var selectedWeekdays: Set<Int> = [2, 3, 4, 5, 6]
    @State private var customEndDate: Date

    // MARK: - Form State

    @State private var isSaving = false
    @State private var showError = false
    @State private var errorMessage = ""

    private let accent = Color(hex: "8B7CFF")

    private var calendar: Calendar {
        Calendar.current
    }

    // MARK: - Options

    private enum RepeatOption: String, CaseIterable {
        case never = "Does not repeat"
        case daily = "Every day"
        case selectedDays = "Selected weekdays"
    }

    private enum RoutineDuration: String, CaseIterable {
        case oneMonth = "1 month"
        case threeMonths = "3 months"
        case fourMonths = "4 months"
        case sixMonths = "6 months"
        case custom = "Choose end date"

        var months: Int? {
            switch self {
            case .oneMonth:
                return 1
            case .threeMonths:
                return 3
            case .fourMonths:
                return 4
            case .sixMonths:
                return 6
            case .custom:
                return nil
            }
        }
    }

    private enum FormError: LocalizedError {
        case invalidEndDate
        case noWeekdays
        case noOccurrences
        case periodTooLong
        case invalidDate

        var errorDescription: String? {
            switch self {
            case .invalidEndDate:
                return "The end date must be on or after the start date."
            case .noWeekdays:
                return "Select at least one weekday."
            case .noOccurrences:
                return "There are no matching weekdays in this period."
            case .periodTooLong:
                return "Choose a period shorter than 10 years."
            case .invalidDate:
                return "The selected dates could not be calculated."
            }
        }
    }

    // MARK: - Initialization

    init(selectedDate: Date) {
        let calendar = Calendar.current
        let now = Date()

        let components = calendar.dateComponents(
            [.hour, .minute],
            from: now
        )

        let initialDate = calendar.date(
            bySettingHour: components.hour ?? 0,
            minute: components.minute ?? 0,
            second: 0,
            of: selectedDate
        ) ?? selectedDate

        _startTime = State(initialValue: initialDate)

        _customEndDate = State(
            initialValue: calendar.date(
                byAdding: .month,
                value: 3,
                to: initialDate
            ) ?? initialDate
        )
    }

    // MARK: - Computed Properties

    private var isRecurring: Bool {
        repeatOption != .never
    }

    private var activeWeekdays: [Int] {
        switch repeatOption {
        case .never:
            return []
        case .daily:
            return Array(1...7)
        case .selectedDays:
            return selectedWeekdays.sorted()
        }
    }

    private var endDate: Date {
        guard let months = duration.months else {
            return calendar.startOfDay(for: customEndDate)
        }

        let firstDay = calendar.startOfDay(for: startTime)

        let exclusiveEnd = calendar.date(
            byAdding: .month,
            value: months,
            to: firstDay
        ) ?? firstDay

        return calendar.date(
            byAdding: .day,
            value: -1,
            to: exclusiveEnd
        ) ?? firstDay
    }

    private var previewDates: [Date] {
        (try? occurrenceDates()) ?? []
    }

    private var canSave: Bool {
        let validTitle = !title.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).isEmpty

        return validTitle && !isSaving && !previewDates.isEmpty
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            AppForm {
                taskSection
                repeatSection

                if isRecurring {
                    durationSection
                    summarySection
                }

                notesSection
            }
            .navigationTitle(
                isRecurring ? "Add Routine" : "Add Task"
            )
            .tint(accent)
            .toolbar {
                toolbar
            }
            .alert(
                "Could not save",
                isPresented: $showError
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    // MARK: - Task Section

    private var taskSection: some View {
        Section("Task") {
            TextField("Title", text: $title)

            Picker("Category", selection: $category) {
                ForEach(TaskCategory.allCases, id: \.self) { category in
                    Text(LocalizedStringKey(category.rawValue))
                        .tag(category)
                }
            }

            DatePicker(
                isRecurring ? "Starts" : "Time",
                selection: $startTime,
                displayedComponents: [.date, .hourAndMinute]
            )
        }
    }

    // MARK: - Repeat Section

    private var repeatSection: some View {
        Section {
            Picker("Repeat", selection: $repeatOption) {
                ForEach(RepeatOption.allCases, id: \.self) { option in
                    Text(option.rawValue)
                        .tag(option)
                }
            }

            if repeatOption == .selectedDays {
                weekdayPicker
            }
        } header: {
            Text("Repetition")
        } footer: {
            if isRecurring {
                Text(
                    "Each day has its own task. Completing or editing one day does not change the others."
                )
            }
        }
    }

    private var weekdayPicker: some View {
        HStack(spacing: 4) {
            ForEach([2, 3, 4, 5, 6, 7, 1], id: \.self) { weekday in
                weekdayButton(weekday)
            }
        }
        .padding(.vertical, 4)
    }

    private func weekdayButton(_ weekday: Int) -> some View {
        let selected = selectedWeekdays.contains(weekday)
        let label = calendar.shortWeekdaySymbols[weekday - 1]

        return Button {
            if selected {
                selectedWeekdays.remove(weekday)
            } else {
                selectedWeekdays.insert(weekday)
            }
        } label: {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .foregroundStyle(
                    selected ? Color.white : Color.primary
                )
                .frame(maxWidth: .infinity)
                .frame(height: 42)
                .background(
                    selected
                        ? accent
                        : Color.secondary.opacity(0.12)
                )
                .clipShape(
                    RoundedRectangle(cornerRadius: 10)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            calendar.weekdaySymbols[weekday - 1]
        )
        .accessibilityAddTraits(
            selected ? .isSelected : []
        )
    }

    // MARK: - Duration Section

    private var durationSection: some View {
        Section("Duration") {
            Picker("Repeat for", selection: $duration) {
                ForEach(RoutineDuration.allCases, id: \.self) { option in
                    Text(option.rawValue)
                        .tag(option)
                }
            }

            if duration == .custom {
                DatePicker(
                    "Last day",
                    selection: $customEndDate,
                    in: calendar.startOfDay(for: startTime)...,
                    displayedComponents: [.date]
                )
            } else {
                LabeledContent("Last day") {
                    Text(
                        endDate,
                        format: .dateTime
                            .day()
                            .month(.abbreviated)
                            .year()
                    )
                }
            }
        }
    }

    // MARK: - Summary Section

    private var summarySection: some View {
        Section("Summary") {
            LabeledContent(
                "Tasks to create",
                value: "\(previewDates.count)"
            )

            LabeledContent("Time") {
                Text(startTime, style: .time)
            }

            if previewDates.isEmpty {
                Text(
                    "Check the selected weekdays and the end date."
                )
                .font(.footnote)
                .foregroundStyle(.orange)
            }
        }
    }

    // MARK: - Notes Section

    private var notesSection: some View {
        Section("Notes") {
            TextField(
                "Add notes...",
                text: $notes,
                axis: .vertical
            )
            .lineLimit(3...6)
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") {
                dismiss()
            }
            .disabled(isSaving)
        }

        ToolbarItem(placement: .confirmationAction) {
            Button(isRecurring ? "Create" : "Save") {
                saveTask()
            }
            .disabled(!canSave)
        }
    }

    // MARK: - Date Generation

    private func occurrenceDates() throws -> [Date] {
        guard isRecurring else { return [startTime] }
        let time = calendar.dateComponents([.hour, .minute], from: startTime)
        let dates = try RecurrenceSchedule.dates(
            from: startTime, through: endDate,
            hour: time.hour ?? 0, minute: time.minute ?? 0,
            weekdays: Set(activeWeekdays), calendar: calendar
        )
        guard !dates.isEmpty else { throw FormError.noOccurrences }
        return dates
    }

    // MARK: - Save

    private func saveTask() {
        guard !isSaving else {
            return
        }

        isSaving = true
        defer { isSaving = false }

        var insertedTasks: [TaskItem] = []
        var insertedSeries: TaskSeries?

        do {
            let dates = try occurrenceDates()

            let cleanTitle = title.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

            guard !cleanTitle.isEmpty else {
                return
            }

            if isRecurring {
                let time = calendar.dateComponents(
                    [.hour, .minute],
                    from: startTime
                )

                let series = TaskSeries(
                    title: cleanTitle,
                    category: category,
                    notes: notes,
                    startDate: calendar.startOfDay(for: startTime),
                    endDate: endDate,
                    hour: time.hour ?? 0,
                    minute: time.minute ?? 0,
                    weekdays: activeWeekdays
                )

                modelContext.insert(series)
                insertedSeries = series
            }

            for date in dates {
                let task = TaskItem(
                    title: cleanTitle,
                    category: category,
                    startTime: date,
                    isCompleted: false,
                    notes: notes,
                    seriesID: insertedSeries?.id,
                    originalScheduledDate: isRecurring ? date : nil
                )

                modelContext.insert(task)
                insertedTasks.append(task)
            }

            try modelContext.save()

            NotificationManager.shared.refreshNotifications()
            dismiss()

        } catch {
            for task in insertedTasks {
                modelContext.delete(task)
            }

            if let series = insertedSeries {
                modelContext.delete(series)
            }

            errorMessage = error.localizedDescription
            showError = true
        }
    }
}
