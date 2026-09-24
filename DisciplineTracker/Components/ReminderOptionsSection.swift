import SwiftUI
import UserNotifications

private enum ReminderIntervalUnit: Int, CaseIterable, Identifiable {
    case minutes = 1
    case hours = 60
    case days = 1_440

    var id: Int { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .minutes: "Minutes"
        case .hours: "Hours"
        case .days: "Days"
        }
    }

    var range: ClosedRange<Double> {
        switch self {
        case .minutes: 1...120
        case .hours: 1...48
        case .days: 1...30
        }
    }
}

struct ReminderOptionsSection: View {
    @Binding var offsets: [Int]
    var startTime: Date? = nil
    var title: LocalizedStringKey = "Notifications"
    var toggleTitle: LocalizedStringKey = "Reminders for this activity"
    @State private var previousSelection: [Int] = []
    @State private var showsCustomInterval = false
    @State private var customValue = 30.0
    @State private var unit = ReminderIntervalUnit.minutes
    @ObservedObject private var manager = NotificationManager.shared
    @AppStorage(ReminderPreferences.enabledKey) private var globallyEnabled = true

    private var customMinutes: Int {
        Int(customValue.rounded()) * unit.rawValue
    }

    private var choices: [Int] {
        Array(Set(ReminderPolicy.presets + offsets)).sorted(by: >)
    }

    var body: some View {
        Section {
            Toggle(toggleTitle, isOn: Binding(
                get: { !offsets.isEmpty },
                set: { enabled in
                    if enabled {
                        offsets = previousSelection.isEmpty ? [10] : previousSelection
                    } else {
                        previousSelection = offsets
                        offsets = []
                    }
                }
            ))
            if !offsets.isEmpty {
                ForEach(choices, id: \.self) { offset in
                    Toggle(isOn: Binding(
                        get: { offsets.contains(offset) },
                        set: { selected in
                            offsets = ReminderPolicy.normalized(selected
                                ? offsets + [offset] : offsets.filter { $0 != offset })
                        }
                    )) {
                        Text(ReminderPolicy.label(offset))
                    }
                }
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showsCustomInterval.toggle()
                    }
                } label: {
                    HStack {
                        Label("More time", systemImage: "slider.horizontal.3")
                        Spacer()
                        Image(systemName: "chevron.down")
                            .rotationEffect(.degrees(showsCustomInterval ? 180 : 0))
                            .foregroundStyle(.secondary)
                    }
                }
                .accessibilityLabel(showsCustomInterval ? "Hide custom interval" : "Choose a custom interval")

                if showsCustomInterval {
                    VStack(alignment: .leading, spacing: 14) {
                        Text(ReminderPolicy.label(customMinutes))
                            .font(.headline)
                            .foregroundStyle(AppTheme.accent)
                            .contentTransition(.numericText())

                        Picker("Unit", selection: $unit) {
                            ForEach(ReminderIntervalUnit.allCases) { option in
                                Text(option.title).tag(option)
                            }
                        }
                        .pickerStyle(.segmented)

                        Slider(value: $customValue, in: unit.range, step: 1)
                            .accessibilityLabel("Custom interval")
                            .accessibilityValue(ReminderPolicy.label(customMinutes))

                        Button("Add this reminder") {
                            offsets = ReminderPolicy.normalized(offsets + [customMinutes])
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(AppTheme.accent)
                        .disabled(offsets.contains(customMinutes))
                    }
                    .padding(.vertical, 6)
                    .onChange(of: unit) { _, newUnit in
                        customValue = min(max(customValue, newUnit.range.lowerBound), newUnit.range.upperBound)
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            if !globallyEnabled {
                Text("All notifications are paused in Profile. Your choices are kept.")
                    .foregroundStyle(.orange)
            } else if !offsets.isEmpty && !manager.isAuthorized {
                if manager.authorizationStatus == .notDetermined {
                    Button("Allow notifications") { manager.requestPermission() }
                } else if manager.authorizationStatus == .denied {
                    Text("Notifications are disabled in iPhone Settings.")
                        .foregroundStyle(.orange)
                    Button("Open notification settings") { manager.openSettings() }
                }
            }
            if let startTime {
                ReminderPreview(offsets: offsets, startTime: startTime)
            }
        } header: {
            Text(title)
        } footer: {
            Text("Select one or more reminders. Switch off an interval to remove it.")
        }
        .task { await manager.updateAuthorizationStatus() }
    }
}

struct ReminderPreview: View {
    let offsets: [Int]
    let startTime: Date
    var isPending = true

    var body: some View {
        TimelineView(.periodic(from: .now, by: 30)) { timeline in
            VStack(alignment: .leading, spacing: 6) {
                if !isPending {
                    Text("No upcoming reminders for a completed or skipped activity.")
                } else if offsets.isEmpty {
                    Text("No reminders")
                } else {
                    Text("Reminder times").fontWeight(.semibold)
                    ForEach(ReminderPolicy.normalized(offsets), id: \.self) { offset in
                        let date = ReminderPolicy.fireDate(start: startTime, offset: offset)
                        HStack(alignment: .top) {
                            Text(date, format: .dateTime.day().month(.abbreviated).year().hour().minute())
                            if date <= timeline.date {
                                Text("Passed — will not be scheduled")
                                    .foregroundStyle(.orange)
                            }
                        }
                    }
                }
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
    }
}
