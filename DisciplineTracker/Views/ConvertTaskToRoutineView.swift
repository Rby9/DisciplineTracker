import SwiftUI
import SwiftData
import Foundation

struct ConvertTaskToRoutineView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    let task: TaskItem

    @State private var firstDay: Date
    @State private var time: Date
    @State private var lastDay: Date
    @State private var reminderOffsets: [Int]
    @State private var months = 3
    @State private var everyDay = true
    @State private var weekdays: Set<Int> = [2, 3, 4, 5, 6]
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var isSaving = false

    init(task: TaskItem) {
        self.task = task
        _reminderOffsets = State(initialValue: task.effectiveReminderOffsets)
        let first = Calendar.current.startOfDay(for: max(Date(), task.startTime))
        _firstDay = State(initialValue: first)
        _time = State(initialValue: task.startTime)
        _lastDay = State(initialValue: RecurrenceSchedule.lastDay(starting: first, months: 3))
    }

    private var activeWeekdays: Set<Int> { everyDay ? Set(1...7) : weekdays }
    private var endDate: Date {
        months == 0 ? lastDay : RecurrenceSchedule.lastDay(starting: firstDay, months: months)
    }
    private var preview: [Date] { (try? dates(now: Date())) ?? [] }

    var body: some View {
        NavigationStack {
            AppForm {
                Section("Original task") {
                    Text(task.title).font(.headline)
                    LabeledContent("Date & time") {
                        Text(task.startTime, format: .dateTime.day().month(.abbreviated).hour().minute())
                    }
                    Label(task.status.rawValue, systemImage: task.status.symbol)
                        .foregroundStyle(task.status.color)
                }
                Section {
                    DatePicker("First day", selection: $firstDay,
                               in: Calendar.current.startOfDay(for: Date())...,
                               displayedComponents: .date)
                    DatePicker("Routine time", selection: $time, displayedComponents: .hourAndMinute)
                    Toggle("Every day", isOn: $everyDay)
                    if !everyDay {
                        ForEach([2, 3, 4, 5, 6, 7, 1], id: \.self) { day in
                            Toggle(Calendar.current.weekdaySymbols[day - 1], isOn: Binding(
                                get: { weekdays.contains(day) },
                                set: { enabled in
                                    if enabled { weekdays.insert(day) } else { weekdays.remove(day) }
                                }
                            ))
                        }
                    }
                } header: { Text("Future schedule") } footer: { Text("The original task keeps its date, time and status. Only future occurrences are added, with at most one new occurrence per day. Its original day is never duplicated.") }

                Section("Duration") {
                    Picker("Repeat for", selection: $months) {
                        Text("1 month").tag(1)
                        Text("3 months").tag(3)
                        Text("4 months").tag(4)
                        Text("6 months").tag(6)
                        Text("Choose end date").tag(0)
                    }
                    if months == 0 {
                        DatePicker("Last day", selection: $lastDay, in: firstDay...,
                                   displayedComponents: .date)
                    } else {
                        LabeledContent("Last day") { Text(endDate, style: .date) }
                    }
                }
                ReminderOptionsSection(offsets: $reminderOffsets, startTime: preview.first)
                Section { Text("Reminder choices apply only to new occurrences. The original task keeps its reminders.") }
                Section("Review") {
                    LabeledContent("Original task kept", value: "1")
                    LabeledContent("New tasks", value: "\(preview.count)")
                    if let first = preview.first {
                        LabeledContent("First new occurrence") {
                            Text(first, format: .dateTime.day().month(.abbreviated).hour().minute())
                        }
                    } else {
                        Text("Choose a period with at least one future occurrence.")
                            .foregroundStyle(.orange)
                    }
                    Text("Manage the schedule later in Weekly → Routines. Editing a task's details changes only that occurrence.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Make recurring")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }.disabled(isSaving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") { save() }
                        .disabled(isSaving || preview.isEmpty || task.seriesID != nil)
                }
            }
            .onChange(of: firstDay) { _, newValue in
                if lastDay < newValue { lastDay = newValue }
            }
            .alert("Could not create routine", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: { Text(errorMessage) }
        }
        .interactiveDismissDisabled(isSaving)
    }

    private func dates(now: Date) throws -> [Date] {
        let clock = Calendar.current.dateComponents([.hour, .minute], from: time)
        return try RecurrenceSchedule.dates(
            from: firstDay, through: endDate,
            hour: clock.hour ?? 0, minute: clock.minute ?? 0,
            weekdays: activeWeekdays, after: now, excludingDay: task.startTime
        )
    }

    private func save() {
        guard !isSaving, task.seriesID == nil else { return }
        isSaving = true
        defer { isSaving = false }
        do {
            let clock = Calendar.current.dateComponents([.hour, .minute], from: time)
            try RoutineConversion.create(
                for: task, firstDay: firstDay, lastDay: endDate,
                hour: clock.hour ?? 0, minute: clock.minute ?? 0,
                weekdays: activeWeekdays, in: modelContext, reminderOffsets: reminderOffsets
            )
            NotificationManager.shared.refreshNotifications()
            if !reminderOffsets.isEmpty && ReminderPreferences.enabled {
                NotificationManager.shared.requestPermission()
            }
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}
