import SwiftUI
import SwiftData

struct AddGoalView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @State private var title = ""
    @State private var period = GoalPeriod.weekly
    @State private var category: TaskCategory?
    @State private var targetCount = 5
    @State private var errorMessage = ""
    @State private var showError = false

    var body: some View {
        NavigationStack {
            AppForm {
                Section("Goal") {
                    TextField("What do you want to achieve?", text: $title)
                        .submitLabel(.done)

                    Picker("Period", selection: $period) {
                        ForEach(GoalPeriod.allCases, id: \.self) { value in
                            Text(value.title).tag(value)
                        }
                    }

                    Picker("Category", selection: $category) {
                        Text("All categories").tag(nil as TaskCategory?)
                        ForEach(TaskCategory.allCases, id: \.self) { value in
                            Text(LocalizedStringKey(value.rawValue)).tag(Optional(value))
                        }
                    }
                }

                Section {
                    Stepper(value: $targetCount, in: 1...500) {
                        LabeledContent("Completed activities", value: String(targetCount))
                    }
                } header: {
                    Text("Target")
                } footer: {
                    Text("Progress increases automatically when matching activities are completed during this period.")
                }
            }
            .navigationTitle("New goal")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                }
            }
            .alert("Could not save goal", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    private func save() {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTitle.isEmpty else {
            errorMessage = String(localized: "Enter a title for the goal.")
            showError = true
            return
        }

        let calendar = Calendar.current
        let now = Date()
        let interval: DateInterval?
        switch period {
        case .weekly:
            interval = calendar.dateInterval(of: .weekOfYear, for: now)
        case .monthly:
            interval = calendar.dateInterval(of: .month, for: now)
        }

        guard let interval else {
            errorMessage = String(localized: "Could not calculate the selected period.")
            showError = true
            return
        }

        modelContext.insert(
            Goal(
                title: cleanTitle,
                period: period,
                category: category,
                targetCount: targetCount,
                startDate: interval.start,
                endDate: interval.end
            )
        )

        do {
            try modelContext.save()
            dismiss()
        } catch {
            modelContext.rollback()
            errorMessage = error.localizedDescription
            showError = true
        }
    }
}
