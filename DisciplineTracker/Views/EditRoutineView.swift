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

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // MARK: - Properties

    let routine: TaskSeries

    @State private var selectedWeekdays: Set<Int>
    @State private var selectedTime: Date
    @State private var endDate: Date
    @State private var effectiveDate: Date

    @State private var reviewedPlan: RoutineChangePlan?
    @State private var showConfirmation = false
    @State private var showError = false
    @State private var errorMessage = ""

    private let accent = Color(hex: "8B7CFF")

    private var calendar: Calendar {
        Calendar.current
    }

    // MARK: - Initialization

    init(routine: TaskSeries) {
        self.routine = routine

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        _selectedWeekdays = State(
            initialValue: Set(routine.weekdays)
        )

        _selectedTime = State(
            initialValue: calendar.date(
                bySettingHour: routine.hour,
                minute: routine.minute,
                second: 0,
                of: today
            ) ?? today
        )

        _endDate = State(initialValue: routine.endDate)

        _effectiveDate = State(
            initialValue: max(
                today,
                calendar.startOfDay(for: routine.startDate)
            )
        )
    }

    // MARK: - Body

    var body: some View {
        Form {
            routineSection
            weekdaysSection
            scheduleSection
            reviewSection
            stopSection
        }
        .navigationTitle("Edit Routine")
        .navigationBarTitleDisplayMode(.inline)
        .tint(accent)
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
    }

    // MARK: - Routine Section

    private var routineSection: some View {
        Section {
            Text(routine.title)
                .font(.headline)

            Text(routine.category.rawValue)
                .foregroundStyle(routine.category.color)
        } header: {
            Text("Routine")
        } footer: {
            Text(
                "Changes apply from the date below. Completed tasks, past tasks and individually edited tasks are preserved."
            )
        }
    }

    // MARK: - Weekdays

    private var weekdaysSection: some View {
        Section("Repeat on") {
            ForEach([2, 3, 4, 5, 6, 7, 1], id: \.self) { weekday in
                Toggle(
                    calendar.weekdaySymbols[weekday - 1],
                    isOn: Binding(
                        get: {
                            selectedWeekdays.contains(weekday)
                        },
                        set: { selected in
                            if selected {
                                selectedWeekdays.insert(weekday)
                            } else {
                                selectedWeekdays.remove(weekday)
                            }
                        }
                    )
                )
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
            .disabled(selectedWeekdays.isEmpty)
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
            weekdays: selectedWeekdays.sorted()
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
                task.notes != routine.notes

            if task.isCompleted ||
                task.startTime <= now ||
                individuallyEdited {
                plan.preservedCount += 1
                continue
            }

            if let desiredDate = desiredDates[originalDay] {
                if task.startTime != desiredDate {
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
            guard !oldRuleIncludes(day) else {
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
                routine.weekdays = freshPlan.weekdays
                routine.hour = freshPlan.hour
                routine.minute = freshPlan.minute
                routine.endDate = freshPlan.lastDay
            }

            try modelContext.save()

            NotificationManager.shared.refreshNotifications()
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