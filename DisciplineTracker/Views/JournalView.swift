import SwiftUI
import SwiftData
import Foundation

struct JournalView: View {

    // MARK: - Environment

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    // MARK: - Data

    @Query private var entries: [JournalEntry]
    @Query private var tasks: [TaskItem]

    // MARK: - Editor State

    @State private var selectedDate: Date
    @State private var note = ""
    @State private var selectedMood: JournalMood?

    @State private var loadedNote = ""
    @State private var loadedMood: JournalMood?
    @State private var hasLoaded = false

    // MARK: - Calendar State

    @State private var showCalendar = false
    @State private var calendarDate: Date
    @State private var confirmedCalendarDate: Date?

    // MARK: - Unsaved Changes

    @State private var pendingDate: Date?
    @State private var showUnsavedChanges = false

    // MARK: - Feedback

    @State private var showError = false
    @State private var errorMessage = ""
    @State private var savedMessage = false

    private let accent = Color(hex: "8B7CFF")

    // MARK: - Initialization

    init(initialDate: Date) {
        _selectedDate = State(initialValue: initialDate)
        _calendarDate = State(initialValue: initialDate)
    }

    // MARK: - Computed Properties

    private var dayTasks: [TaskItem] {
        tasks.filter {
            Calendar.current.isDate(
                $0.startTime,
                inSameDayAs: selectedDate
            )
        }
    }

    private var completedCount: Int {
        dayTasks.filter { $0.isCompleted }.count
    }

    private var isDirty: Bool {
        note != loadedNote || selectedMood != loadedMood
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            AppForm {
                dateSection
                taskSummary
                moodSection
                noteSection

                if savedMessage && !isDirty {
                    Section {
                        Label(
                            "Saved",
                            systemImage: "checkmark.circle.fill"
                        )
                        .foregroundStyle(accent)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color(hex: "0D0B16"))
            .navigationTitle("Journal")
            .navigationBarTitleDisplayMode(.inline)
            .tint(accent)
            .toolbar {
                toolbar
            }
            .onAppear {
                guard !hasLoaded else { return }
                hasLoaded = true
                loadEntry(for: selectedDate)
            }
            .sheet(
                isPresented: $showCalendar,
                onDismiss: calendarDidClose
            ) {
                calendarSheet
            }
            .confirmationDialog(
                "Unsaved changes",
                isPresented: $showUnsavedChanges,
                titleVisibility: .visible
            ) {
                Button("Save and change day") {
                    if saveEntry() {
                        openPendingDate()
                    }
                }

                Button(
                    "Discard and change day",
                    role: .destructive
                ) {
                    openPendingDate()
                }

                Button("Cancel", role: .cancel) {
                    pendingDate = nil
                }
            } message: {
                Text(
                    "Save your journal entry before opening another day?"
                )
            }
            .alert("Could not save", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
        .preferredColorScheme(.dark)
        .interactiveDismissDisabled(isDirty)
    }

    // MARK: - Date Section

    private var dateSection: some View {
        Section {
            Button {
                calendarDate = selectedDate
                confirmedCalendarDate = nil
                showCalendar = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "calendar")
                        .foregroundStyle(accent)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(
                            selectedDate,
                            format: .dateTime
                                .weekday(.wide)
                                .day()
                                .month(.wide)
                                .year()
                        )
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)

                        Text("Tap to choose another day")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if !Calendar.current.isDateInToday(selectedDate) {
                Button("Back to today") {
                    requestDate(Date())
                }
            }
        }
    }

    // MARK: - Calendar Sheet

    private var calendarSheet: some View {
        NavigationStack {
            ScrollView {
                DatePicker(
                    "Choose a day",
                    selection: $calendarDate,
                    displayedComponents: [.date]
                )
                .datePickerStyle(.graphical)
                .tint(accent)
                .padding(16)
            }
            .background(Color(hex: "0D0B16"))
            .navigationTitle("Choose a day")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        confirmedCalendarDate = nil
                        showCalendar = false
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        confirmedCalendarDate = calendarDate
                        showCalendar = false
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Task Summary

    private var taskSummary: some View {
        Section {
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 18) {
                summaryValue("\(dayTasks.count)", label: "Planned")
                summaryValue("\(completedCount)", label: "Completed")
                summaryValue("\(dayTasks.filter { $0.isPending }.count)", label: "Pending")
                summaryValue("\(dayTasks.filter { $0.isSkipped }.count)", label: "Skipped")
            }
            .padding(.vertical, 6)
        } header: {
            Text("Tasks scheduled for this day")
        } footer: {
            Text(
                "This summary reflects the tasks currently assigned to this date."
            )
        }
    }

    private func summaryValue(
        _ value: String,
        label: String
    ) -> some View {
        VStack(spacing: 5) {
            Text(value)
                .font(.system(size: 24, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(accent)

            Text(label)
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - Mood Section

    private var moodSection: some View {
        Section {
            HStack(spacing: 5) {
                ForEach(JournalMood.allCases, id: \.self) { mood in
                    moodButton(mood)
                }
            }
            .padding(.vertical, 4)
        } header: {
            Text("How did you feel?")
        } footer: {
            Text("Optional. Tap the selected mood again to clear it.")
        }
    }

    private func moodButton(_ mood: JournalMood) -> some View {
        let selected = selectedMood == mood

        return Button {
            selectedMood = selected ? nil : mood
        } label: {
            VStack(spacing: 7) {
                Text(mood.emoji)
                    .font(.system(size: 27))

                Text(mood.rawValue)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(selected ? .white : .secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                selected ? accent.opacity(0.25) : Color.clear
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(mood.rawValue)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    // MARK: - Notes

    private var noteSection: some View {
        Section {
            TextField(
                "What went well? What would you change?",
                text: $note,
                axis: .vertical
            )
            .lineLimit(8...16)
        } header: {
            Text("Your thoughts")
        } footer: {
            Text(
                "Write as much or as little as you want. Tap Save to keep your changes."
            )
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button(isDirty ? "Cancel" : "Close") {
                dismiss()
            }
        }

        ToolbarItem(placement: .confirmationAction) {
            Button("Save") {
                _ = saveEntry()
            }
            .disabled(!isDirty)
        }
    }

    // MARK: - Navigation

    private func calendarDidClose() {
        guard let date = confirmedCalendarDate else { return }
        confirmedCalendarDate = nil
        requestDate(date)
    }

    private func requestDate(_ date: Date) {
        guard JournalEntry.key(for: date)
                != JournalEntry.key(for: selectedDate) else {
            return
        }

        if isDirty {
            pendingDate = date
            showUnsavedChanges = true
        } else {
            loadEntry(for: date)
        }
    }

    private func openPendingDate() {
        guard let date = pendingDate else { return }
        pendingDate = nil
        loadEntry(for: date)
    }

    // MARK: - Loading

    private func entry(for date: Date) -> JournalEntry? {
        let key = JournalEntry.key(for: date)
        return entries.first { $0.dayKey == key }
    }

    private func loadEntry(for date: Date) {
        let matchingEntry = entry(for: date)
        let entryNote = matchingEntry?.note ?? ""

        let entryMood: JournalMood?
        if let rawMood = matchingEntry?.moodRaw {
            entryMood = JournalMood(rawValue: rawMood)
        } else {
            entryMood = nil
        }

        selectedDate = date
        note = entryNote
        selectedMood = entryMood
        loadedNote = entryNote
        loadedMood = entryMood
        savedMessage = false
    }

    // MARK: - Saving

    private func saveEntry() -> Bool {
        let cleanNote = note.trimmingCharacters(
            in: .whitespacesAndNewlines
        )
        let dateToSave = selectedDate
        var hasStartedChanges = false

        do {
            try modelContext.save()
            hasStartedChanges = true

            let matchingEntry = entry(for: dateToSave)

            if cleanNote.isEmpty && selectedMood == nil {
                if let matchingEntry {
                    modelContext.delete(matchingEntry)
                }
            } else if let matchingEntry {
                matchingEntry.note = cleanNote
                matchingEntry.moodRaw = selectedMood?.rawValue
                matchingEntry.updatedAt = Date()
            } else {
                let newEntry = JournalEntry(
                    date: Calendar.current.startOfDay(for: dateToSave),
                    note: cleanNote,
                    moodRaw: selectedMood?.rawValue
                )
                modelContext.insert(newEntry)
            }

            try modelContext.save()

            note = cleanNote
            loadedNote = cleanNote
            loadedMood = selectedMood
            savedMessage = true
            return true

        } catch {
            if hasStartedChanges {
                modelContext.rollback()
            }

            errorMessage = error.localizedDescription
            showError = true
            return false
        }
    }
}
