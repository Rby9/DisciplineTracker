import ActivityKit
import SwiftUI

struct LiveActivitySettingsSection: View {
    let tasks: [TaskItem]

    @AppStorage(LiveActivityPreferences.enabledKey)
    private var isEnabled = true

    @AppStorage(LiveActivityPreferences.leadMinutesKey)
    private var leadMinutes = 30

    private var leadMinutesBinding: Binding<Double> {
        Binding(
            get: { Double(leadMinutes) },
            set: { leadMinutes = Int($0.rounded()) }
        )
    }

    var body: some View {
        Section {
            Toggle("Show upcoming activity", isOn: $isEnabled)

            if isEnabled {
                VStack(alignment: .leading, spacing: 10) {
                    LabeledContent("Show before start") {
                        Text("\(leadMinutes) min")
                            .foregroundStyle(AppTheme.accent)
                            .contentTransition(.numericText())
                    }

                    Slider(value: leadMinutesBinding, in: 5...120, step: 5)
                        .accessibilityLabel("Time before Live Activity starts")
                        .accessibilityValue("\(leadMinutes) minutes")
                }
            }

            if !ActivityAuthorizationInfo().areActivitiesEnabled {
                Text("Live Activities are disabled in iPhone Settings.")
                    .font(.footnote)
                    .foregroundStyle(.orange)
            }
        } header: {
            Text("Dynamic Island")
        } footer: {
            Text("Shows the next activity, its countdown and today's progress. On iOS 26 or later, Ritvara can schedule it automatically.")
        }
        .onChange(of: isEnabled) { _, _ in synchronize() }
        .onChange(of: leadMinutes) { _, _ in synchronize() }
    }

    private func synchronize() {
        Task {
            await RitvaraLiveActivityManager.synchronize(tasks: tasks)
        }
    }
}
