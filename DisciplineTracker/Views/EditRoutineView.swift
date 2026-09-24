//
//  EditRoutineView.swift
//  DisciplineTracker
//
//  Created by Robert Balaban on 6/9/26.
//


import SwiftUI
import SwiftData
import Foundation

struct EditRoutineView: View {
    private enum RepeatPattern: String, CaseIterable, Identifiable {
        case selectedDays, interval
        var id: Self { self }
        var title: LocalizedStringResource {
            switch self {
            case .selectedDays: "Selected days"
            case .interval: "Every N days"
            }
        }
    }

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // MARK: - Properties

    let routine: TaskSeries

    @Query private var tasks: [TaskItem]

    @State private var selectedWeekdays: Set<Int>
    @State private var repeatPattern: RepeatPattern
    @State private var intervalDays: Int
    @State private var selectedTime: Date
    @State private var endDate: Date
    @State private var effectiveDate: Date
    @State private var reminderOffsets: [Int]
    @State private var pauseUntil: Date
    @State private var showPauseConfirmation = false

    @State private var reviewedPlan: RoutineChangePlan?
    @State private var showConfirmation = false
    @State private var showError = false
    @State private var errorMessage = ""

    private var calendar: Calendar {
        Calendar.current
    }

    // MARK: - Initialization

    init(routine: TaskSeries) {
        self.routine = routine
        _reminderOffsets = State(initialValue: routine.effectiveReminderOffsets)

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        _selectedWeekdays = State(
            initialValue: Set(routine.weekdays)
        )
        _repeatPattern = State(initialValue: routine.repeatIntervalDays == nil ? .selectedDays : .interval)
        _intervalDays = State(initialValue: routine.repeatIntervalDays ?? 2)

        _selectedTime = State(
            initialValue: calendar.date(
                bySettingHour: routine.hour,
                minute: routine.minute,
                second: 0,
                of: today
            ) ?? today
        )

        _endDate = State(initialValue: routine.endDate)
        _pauseUntil = State(initialValue: calendar.date(byAdding: .day, value: 7, to: today) ?? today)

        _effectiveDate = State(
            initialValue: max(
                today,
                calendar.startOfDay(for: routine.startDate)
            )
        )
    }

    // MARK: - Body

    var body: some View {
        AppForm {
            routineSection
            performanceSection
            historySection
            frequencySection
            scheduleSection
            pauseSection
            ReminderOptionsSection(offsets: $reminderOffsets, startTime: reminderPreviewDate)
            reviewSection
            stopSection
        }
        .navigationTitle("Edit Routine")
        .navigationBarTitleDisplayMode(.inline)
        .tint(AppTheme.accent)
        .confirmationDialog(
            "Review changes",
            isPresented: $showConfirmation,
            titleVisibility: .visible
        ) {
            if let plan = reviewedPlan {
                Button(
                    plan.isStopping ? "Stop routine" : "Apply changes",
                    role: plan.isStopping ? .destructive : nil
                ) {
                    applyReviewedPlan()
                }
            }

            Button("Cancel", role: .cancel) {}
        } message: {
            if let plan = reviewedPlan {
                Text(plan.summary)
            }
        }
        .alert(
            "Could not apply changes",
            isPresented: $showError
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .confirmationDialog(
            "Pause this routine?",
            isPresented: $showPauseConfirmation,
            titleVisibility: .visible
        ) {
            Button("Pause routine") { pauseRoutine() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Upcoming occurrences through the selected day will be removed. They will not count as missed.")
        }
    }

    // MARK: - Performance

    private var streakSummary: RoutineStreakSummary {
        RoutineStreakCalculator.summary(for: routine, tasks: tasks)
    }

    private var adherence: Double {
        guard streakSummary.dueOccurrences > 0 else { return 0 }
        return Double(streakSummary.completedOccurrences)
            / Double(streakSummary.dueOccurrences)
    }

    private var missedOccurrences: Int {
        max(streakSummary.dueOccurrences - streakSummary.completedOccurrences, 0)
    }

    private var performanceSection: some View {
        Section {
            HStack(spacing: 20) {
                ZStack {
                    Circle()
                        .stroke(AppTheme.border, lineWidth: 9)
                    Circle()
                        .trim(from: 0, to: adherence)
                        .stroke(
                            AppTheme.accent,
                            style: StrokeStyle(lineWidth: 9, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 1) {
                        Text(adherence, format: .percent.precision(.fractionLength(0)))
                            .font(.headline.monospacedDigit())
                        Text("success")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 94, height: 94)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Routine completion rate")
                .accessibilityValue(adherence.formatted(.percent.precision(.fractionLength(0))))

                VStack(spacing: 10) {
                    performanceMetric(
                        value: streakSummary.current,
                        label: "Current streak",
                        icon: "flame.fill",
                        color: .orange
                    )
                    performanceMetric(
                        value: streakSummary.longest,
                        label: "Personal best",
                        icon: "trophy.fill",
                        color: .yellow
                    )
                }
            }
            .padding(.vertical, 8)

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 10) { performanceTotals }
                VStack(spacing: 10) { performanceTotals }
            }
        } header: {
            Text("Performance")
        } footer: {
            Text("Only scheduled occurrences whose time has passed are included.")
        }
    }

    @ViewBuilder
    private var performanceTotals: some View {
        performanceTotal(
            value: streakSummary.completedOccurrences,
            label: "Completed",
            color: AppTheme.accent
        )
        performanceTotal(
            value: missedOccurrences,
            label: "Missed",
            color: .red
        )
        performanceTotal(
            value: routine.excludedDayKeys?.count ?? 0,
            label: "Pauses",
            color: .secondary
        )
    }

    private func performanceMetric(
        value: Int,
        label: LocalizedStringKey,
        icon: String,
        color: Color
    ) -> some View {
        HStack(spacing: 9) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 22)
            VStack(alignment: .leading, spacing: 1) {
                Text(value, format: .number)
                    .font(.headline.monospacedDigit())
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
    }

    private func performanceTotal(
        value: Int,
        label: LocalizedStringKey,
        color: Color
    ) -> some View {
        VStack(spacing: 3) {
            Text(value, format: .number)
                .font(.headline.monospacedDigit())
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity)
        .background(color.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - History

    private var occurrenceHistory: [RoutineOccurrence] {
        RoutineStreakCalculator.history(for: routine, tasks: tasks)
    }

    private var historySection: some View {
        Section {
            if occurrenceHistory.isEmpty {
                ContentUnavailableView(
                    "No history yet",
                    systemImage: "calendar.badge.clock",
                    description: Text("Scheduled appearances will be shown here.")
                )
            } else {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 7),
                    spacing: 12
                ) {
                    ForEach(occurrenceHistory) { occurrence in
                        occurrenceTile(occurrence)
                    }
                }
                .padding(.vertical, 8)

                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 14) { historyLegend }
                    VStack(alignment: .leading, spacing: 8) { historyLegend }
                }
            }
        } header: {
            Text("Recent routine history")
        } footer: {
            Text("Shows up to the last 28 scheduled appearances. Pauses do not count as misses.")
        }
    }

    private func occurrenceTile(_ occurrence: RoutineOccurrence) -> some View {
        VStack(spacing: 5) {
            ZStack {
                Circle()
                    .fill(occurrenceColor(occurrence.state).opacity(0.16))
                Image(systemName: occurrenceSymbol(occurrence.state))
                    .font(.caption.bold())
                    .foregroundStyle(occurrenceColor(occurrence.state))
            }
            .frame(width: 34, height: 34)

            Text(occurrence.date, format: .dateTime.day())
                .font(.caption2.bold().monospacedDigit())
            Text(occurrence.date, format: .dateTime.month(.abbreviated))
                .font(.system(size: 9))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(occurrence.date.formatted(date: .complete, time: .omitted))
        .accessibilityValue(occurrenceName(occurrence.state))
    }

    @ViewBuilder
    private var historyLegend: some View {
        legendItem("Done", state: .completed)
        legendItem("Missed", state: .missed)
        legendItem("Paused", state: .paused)
        legendItem("Upcoming", state: .upcoming)
    }

    private func legendItem(
        _ title: LocalizedStringKey,
        state: RoutineOccurrenceState
    ) -> some View {
        Label {
            Text(title)
        } icon: {
            Image(systemName: occurrenceSymbol(state))
                .foregroundStyle(occurrenceColor(state))
        }
        .font(.caption2)
    }

    private func occurrenceColor(_ state: RoutineOccurrenceState) -> Color {
        switch state {
        case .completed: AppTheme.accent
        case .missed: .red
        case .paused: .secondary
        case .upcoming: .blue
        }
    }

    private func occurrenceSymbol(_ state: RoutineOccurrenceState) -> String {
        switch state {
        case .completed: "checkmark"
        case .missed: "xmark"
        case .paused: "pause.fill"
        case .upcoming: "clock"
        }
    }

    private func occurrenceName(_ state: RoutineOccurrenceState) -> String {
        switch state {
        case .completed: String(localized: "Completed")
        case .missed: String(localized: "Missed")
        case .paused: String(localized: "Paused")
        case .upcoming: String(localized: "Upcoming")
        }
    }

    // MARK: - Routine Section

    private var routineSection: some View {
        Section {
            Text(routine.title)
                .font(.headline)

            Text(LocalizedStringKey(routine.category.rawValue))
                .foregroundStyle(routine.category.color)
        } header: {
            Text("Routine")
        } footer: {
            Text(
                "Changes apply from the date below. Completed or skipped tasks, past tasks and individually edited tasks are preserved."
            )
        }
    }

    // MARK: - Weekdays

    private var frequencySection: some View {
        Section("Frequency") {
            Picker("Repeat pattern", selection: $repeatPattern) {
                ForEach(RepeatPattern.allCases) { pattern in
                    Text(pattern.title).tag(pattern)
                }
            }

            if repeatPattern == .selectedDays {
                ForEach([2, 3, 4, 5, 6, 7, 1], id: \.self) { weekday in
                    Toggle(
                        calendar.weekdaySymbols[weekday - 1],
                        isOn: Binding(
                            get: { selectedWeekdays.contains(weekday) },
                            set: { selected in
                                if selected { selectedWeekdays.insert(weekday) }
                                else { selectedWeekdays.remove(weekday) }
                            }
                        )
                    )
                }
            } else {
                Stepper(value: $intervalDays, in: 2...30) {
                    LabeledContent("Repeat interval", value: "Every \(intervalDays) days")
                }
            }
        }
    }

    // MARK: - Schedule

    private var scheduleSection: some View {
        Section("Schedule") {
            DatePicker(
                "Time",
                selection: $selectedTime,
                displayedComponents: [.hourAndMinute]
            )

            DatePicker(
                "Apply from",
                selection: $effectiveDate,
                in: calendar.startOfDay(for: Date())...,
                displayedComponents: [.date]
            )

            DatePicker(
                "Last day",
                selection: $endDate,
                displayedComponents: [.date]
            )
        }
    }

    private var pauseSection: some View {
        Section {
            DatePicker(
                "Pause through",
                selection: $pauseUntil,
                in: calendar.startOfDay(for: Date())...max(endDate, calendar.startOfDay(for: Date())),
                displayedComponents: .date
            )

            Button {
                showPauseConfirmation = true
            } label: {
                Label("Pause routine temporarily", systemImage: "pause.circle")
            }
        } header: {
            Text("Temporary pause")
        } footer: {
            Text("Completed and individually edited activities are preserved. The routine resumes automatically after this date.")
        }
    }

    private var reminderPreviewDate: Date? {
        let time = calendar.dateComponents([.hour, .minute], from: selectedTime)
        return try? RecurrenceSchedule.dates(
            from: max(effectiveDate, routine.startDate), through: endDate,
            hour: time.hour ?? 0, minute: time.minute ?? 0,
            weekdays: selectedWeekdays, after: Date()
        ).first
    }

    private func pauseRoutine() {
        let now = Date()
        let firstDay = calendar.startOfDay(for: now)
        let lastDay = calendar.startOfDay(for: min(pauseUntil, routine.endDate))

        do {
            let dates = try RecurrenceSchedule.dates(
                from: firstDay,
                through: lastDay,
                hour: routine.hour,
                minute: routine.minute,
                weekdays: Set(routine.weekdays),
                intervalDays: routine.repeatIntervalDays,
                anchoredAt: routine.startDate,
                after: now
            )
            let newKeys = Set(dates.map(JournalEntry.key(for:)))
            let existingKeys = Set(routine.excludedDayKeys ?? [])
            routine.excludedDayKeys = Array(existingKeys.union(newKeys)).sorted()

            let affectedTasks = tasks.filter { task in
                guard task.seriesID == routine.id, task.isPending else { return false }
                let originalDate = task.originalScheduledDate ?? task.startTime
                let key = JournalEntry.key(for: originalDate)
                let individuallyEdited = task.originalScheduledDate == nil || task.startTime != originalDate || task.title != routine.title
                return newKeys.contains(key) && !individuallyEdited && task.startTime > now
            }
            affectedTasks.forEach(modelContext.delete)
            try modelContext.save()
            NotificationManager.shared.refreshNotifications()
        } catch {
            modelContext.rollback()
            presentError(error)
        }
    }

    // MARK: - Review

    private var reviewSection: some View {
        Section {
            Button {
                prepareReview(stopping: false)
            } label: {
                Label(
                    "Review changes",
                    systemImage: "checkmark.circle"
                )
            }
            .disabled(repeatPattern == .selectedDays && selectedWeekdays.isEmpty)
        } footer: {
            Text(
                "Review shows how many tasks will be added, updated or removed. Nothing changes until you confirm."
            )
        }
    }

    // MARK: - Stop

    private var stopSection: some View {
        Section {
            Button(role: .destructive) {
                prepareReview(stopping: true)
            } label: {
                Label(
                    "Stop routine from selected date",
                    systemImage: "stop.circle"
                )
            }
        } footer: {
            Text(
                "Removes upcoming, uncompleted appearances from “Apply from”. Individually edited appearances remain."
            )
        }
    }

    // MARK: - Prepare Review

    private func prepareReview(stopping: Bool) {
        do {
            reviewedPlan = try buildPlan(stopping: stopping)
            showConfirmation = true
        } catch {
            presentError(error)
        }
    }

    // MARK: - Build Plan

    private func buildPlan(
        stopping: Bool
    ) throws -> RoutineChangePlan {
        let allTasks = try modelContext.fetch(
            FetchDescriptor<TaskItem>()
        )

        let routineTasks = allTasks.filter {
            $0.seriesID == routine.id
        }

        let now = Date()
        let today = calendar.startOfDay(for: now)
        let effectiveDay = calendar.startOfDay(for: effectiveDate)

        guard effectiveDay >= today else {
            throw RoutineEditError(
                message: "Choose today or a future date for Apply from."
            )
        }

        let firstDay = max(
            calendar.startOfDay(for: routine.startDate),
            effectiveDay
        )

        let lastDay = calendar.startOfDay(for: endDate)

        if !stopping {
            guard !selectedWeekdays.isEmpty else {
                throw RoutineEditError(
                    message: "Select at least one weekday."
                )
            }

            guard lastDay >= firstDay else {
                throw RoutineEditError(
                    message: "The last day must be on or after the first affected day."
                )
            }
        }

        let time = calendar.dateComponents(
            [.hour, .minute],
            from: selectedTime
        )

        let hour = time.hour ?? 0
        let minute = time.minute ?? 0

        var desiredDates: [Date: Date] = [:]

        if !stopping {
            let span = calendar.dateComponents(
                [.day],
                from: firstDay,
                to: lastDay
            ).day ?? 0

            guard span < 3650 else {
                throw RoutineEditError(
                    message: "Choose a period shorter than 10 years."
                )
            }

            for offset in 0...span {
                guard let day = calendar.date(
                    byAdding: .day,
                    value: offset,
                    to: firstDay
                ) else {
                    throw RoutineEditError(
                        message: "Could not calculate the selected dates."
                    )
                }

                let weekday = calendar.component(
                    .weekday,
                    from: day
                )

                guard selectedWeekdays.contains(weekday) else {
                    continue
                }

                guard let date = calendar.date(
                    bySettingHour: hour,
                    minute: minute,
                    second: 0,
                    of: day
                ),
                calendar.isDate(date, inSameDayAs: day) else {
                    throw RoutineEditError(
                        message: "Could not calculate the time for one of the days."
                    )
                }

                guard date > now else {
                    continue
                }

                desiredDates[day] = date
            }
        }

        var plan = RoutineChangePlan(
            isStopping: stopping,
            effectiveDay: effectiveDay,
            lastDay: lastDay,
            hour: hour,
            minute: minute,
            weekdays: selectedWeekdays.sorted(),
            reminderOffsets: ReminderPolicy.normalized(reminderOffsets)
        )

        var occupiedDays: Set<Date> = []

        for task in routineTasks {
            let originalDate =
                task.originalScheduledDate ?? task.startTime

            let originalDay = calendar.startOfDay(
                for: originalDate
            )

            // Also prevents duplicating a moved occurrence.
            occupiedDays.insert(originalDay)

            guard originalDay >= effectiveDay else {
                continue
            }

            let individuallyEdited =
                task.originalScheduledDate == nil ||
                task.startTime != originalDate ||
                task.title != routine.title ||
                task.category != routine.category ||
                task.notes != routine.notes ||
                task.reminderOverride == true

            if !task.isPending ||
                task.startTime <= now ||
                individuallyEdited {
                plan.preservedCount += 1
                continue
            }

            if let desiredDate = desiredDates[originalDay] {
                if task.startTime != desiredDate || task.effectiveReminderOffsets != plan.reminderOffsets {
                    plan.updates.append(
                        RoutineTaskUpdate(
                            task: task,
                            date: desiredDate
                        )
                    )
                }
            } else {
                // Do not delete today's task just because
                // the newly selected time has already passed.
                if !stopping &&
                    originalDay >= firstDay &&
                    originalDay <= lastDay &&
                    selectedWeekdays.contains(
                        calendar.component(
                            .weekday,
                            from: originalDay
                        )
                    ) {
                    plan.preservedCount += 1
                    continue
                }

                plan.removals.append(task)
            }
        }

        for (day, date) in desiredDates {
            guard !occupiedDays.contains(day) else {
                continue
            }

            // If this date belonged to the old rule but its task
            // is missing, preserve the individual deletion.
            guard !oldRuleIncludes(day),
                  !(routine.excludedDayKeys ?? []).contains(JournalEntry.key(for: day)) else {
                continue
            }

            plan.additions.append(date)
        }

        plan.additions.sort()
        return plan
    }

    // MARK: - Old Rule

    private func oldRuleIncludes(_ day: Date) -> Bool {
        let start = calendar.startOfDay(for: routine.startDate)
        let end = calendar.startOfDay(for: routine.endDate)

        guard day >= start && day <= end else {
            return false
        }

        let weekday = calendar.component(.weekday, from: day)
        return routine.weekdays.contains(weekday)
    }

    // MARK: - Apply

    private func applyReviewedPlan() {
        guard let reviewedPlan else {
            return
        }

        var startedChanges = false

        do {
            // Establish a saved baseline before this operation.
            try modelContext.save()

            let freshPlan = try buildPlan(
                stopping: reviewedPlan.isStopping
            )

            guard freshPlan.signature == reviewedPlan.signature else {
                throw RoutineEditError(
                    message: "The affected tasks changed. Tap Review changes again to see the updated numbers."
                )
            }

            startedChanges = true

            for task in freshPlan.removals {
                modelContext.delete(task)
            }

            for update in freshPlan.updates {
                update.task.reminderOffsets = freshPlan.reminderOffsets
                update.task.snoozedUntil = nil
                update.task.snoozedStartTime = nil
                update.task.startTime = update.date
                update.task.originalScheduledDate = update.date
            }

            for date in freshPlan.additions {
                let task = TaskItem(
                    title: routine.title,
                    category: routine.category,
                    startTime: date,
                    isCompleted: false,
                    notes: routine.notes,
                    seriesID: routine.id,
                    originalScheduledDate: date
                )

                task.reminderOffsets = freshPlan.reminderOffsets
                modelContext.insert(task)
            }

            if freshPlan.isStopping {
                let previousDay = calendar.date(
                    byAdding: .day,
                    value: -1,
                    to: freshPlan.effectiveDay
                ) ?? freshPlan.effectiveDay

                routine.endDate = min(
                    routine.endDate,
                    previousDay
                )
            } else {
                routine.reminderOffsets = freshPlan.reminderOffsets
                routine.weekdays = freshPlan.weekdays
                routine.hour = freshPlan.hour
                routine.minute = freshPlan.minute
                routine.endDate = freshPlan.lastDay
            }

            try modelContext.save()

            NotificationManager.shared.refreshNotifications()
            if !freshPlan.isStopping && !reminderOffsets.isEmpty && ReminderPreferences.enabled {
                NotificationManager.shared.requestPermission()
            }
            dismiss()

        } catch {
            if startedChanges {
                modelContext.rollback()
            }

            presentError(error)
        }
    }

    // MARK: - Errors

    private func presentError(_ error: Error) {
        errorMessage = error.localizedDescription
        showError = true
    }
}


// MARK: - Change Plan

private struct RoutineChangePlan {

    let isStopping: Bool
    let effectiveDay: Date
    let lastDay: Date
    let hour: Int
    let minute: Int
    let weekdays: [Int]
    let reminderOffsets: [Int]

    var additions: [Date] = []
    var updates: [RoutineTaskUpdate] = []
    var removals: [TaskItem] = []
    var preservedCount = 0

    var summary: String {
        """
        From \(effectiveDay.formatted(date: .abbreviated, time: .omitted)):

        Add: \(additions.count)
        Update: \(updates.count)
        Remove: \(removals.count)

        Protected appearances kept: \(preservedCount)

        Earlier history remains unchanged.
        """
    }

    var signature: String {
        let added = additions
            .map { String($0.timeIntervalSince1970) }
            .sorted()
            .joined(separator: ",")

        let updated = updates
            .map {
                "\($0.task.id.uuidString):\($0.date.timeIntervalSince1970)"
            }
            .sorted()
            .joined(separator: ",")

        let removed = removals
            .map { $0.id.uuidString }
            .sorted()
            .joined(separator: ",")

        return [
            String(isStopping),
            String(effectiveDay.timeIntervalSince1970),
            String(lastDay.timeIntervalSince1970),
            String(hour),
            String(minute),
            weekdays.map { String($0) }.joined(separator: ","),
            reminderOffsets.map { String($0) }.joined(separator: ","),
            added,
            updated,
            removed,
            String(preservedCount)
        ].joined(separator: "|")
    }
}

private struct RoutineTaskUpdate {
    let task: TaskItem
    let date: Date
}

private struct RoutineEditError: LocalizedError {
    let message: String

    var errorDescription: String? {
        message
    }
}
