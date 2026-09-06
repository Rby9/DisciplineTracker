//
//  RoutinesView.swift
//  DisciplineTracker
//
//  Created by Robert Balaban on 6/9/26.
//


import SwiftUI
import SwiftData
import Foundation

struct RoutinesView: View {

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss

    // MARK: - Properties

    @Query(sort: \TaskSeries.startDate, order: .reverse)
    private var routines: [TaskSeries]

    private let accent = Color(hex: "8B7CFF")

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {
                if routines.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "repeat")
                            .font(.system(size: 32))
                            .foregroundStyle(accent)

                        Text("No routines yet")
                            .font(.headline)

                        Text("Add a task and choose a repeat option.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 30)
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(routines) { routine in
                        NavigationLink {
                            EditRoutineView(routine: routine)
                        } label: {
                            routineRow(routine)
                        }
                        .listRowBackground(Color(hex: "161426"))
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color(hex: "0D0B16"))
            .navigationTitle("Routines")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
        .tint(accent)
        .preferredColorScheme(.dark)
    }

    // MARK: - Row

    private func routineRow(_ routine: TaskSeries) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(routine.title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)

                Spacer()

                Text(status(for: routine))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(accent)
            }

            Text(
                "\(weekdayText(routine.weekdays)) · \(timeText(routine))"
            )
            .font(.system(size: 13))
            .foregroundStyle(.white.opacity(0.7))

            Text(
                "Until \(routine.endDate.formatted(date: .abbreviated, time: .omitted))"
            )
            .font(.system(size: 12))
            .foregroundStyle(.white.opacity(0.45))
        }
        .padding(.vertical, 8)
    }

    // MARK: - Helpers

    private func weekdayText(_ weekdays: [Int]) -> String {
        if Set(weekdays) == Set(1...7) {
            return "Every day"
        }

        let calendar = Calendar.current

        return [2, 3, 4, 5, 6, 7, 1]
            .filter { weekdays.contains($0) }
            .map { calendar.shortWeekdaySymbols[$0 - 1] }
            .joined(separator: ", ")
    }

    private func timeText(_ routine: TaskSeries) -> String {
        let date = Calendar.current.date(
            bySettingHour: routine.hour,
            minute: routine.minute,
            second: 0,
            of: Date()
        ) ?? Date()

        return date.formatted(date: .omitted, time: .shortened)
    }

    private func status(for routine: TaskSeries) -> String {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        if calendar.startOfDay(for: routine.endDate) < today {
            return "Ended"
        }

        if calendar.startOfDay(for: routine.startDate) > today {
            return "Upcoming"
        }

        return "Active"
    }
}