import SwiftUI
import UserNotifications

struct ReminderOptionsSection: View {
    @Binding var offsets: [Int]
    var startTime: Date? = nil
    var title: LocalizedStringKey = "Notifications"
    var toggleTitle: LocalizedStringKey = "Reminders for this activity"
    @State private var previousSelection: [Int] = []
    @State private var customValue = ""
    @State private var unit = 1
    @ObservedObject private var manager = NotificationManager.shared
    @AppStorage(ReminderPreferences.enabledKey) private var globallyEnabled = true

    private var customMinutes: Int? {
        guard let value = Int(customValue), value > 0,
              value <= ReminderPolicy.maximumMinutes / unit else { return nil }
        return value * unit
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
                HStack {
                    TextField("Custom interval", text: $customValue)
                        .keyboardType(.numberPad)
                        .accessibilityLabel("Custom interval")
                    Picker("Unit", selection: $unit) {
                        Text("Minutes").tag(1)
                        Text("Hours").tag(60)
                    }
                    .labelsHidden()
                    .accessibilityLabel("Unit")
                }
                Button("Add interval") {
                    guard let minutes = customMinutes else { return }
                    offsets = ReminderPolicy.normalized(offsets + [minutes])
                    customValue = ""
                }
                .disabled(customMinutes == nil || offsets.contains(customMinutes ?? -1))
                if !customValue.isEmpty && customMinutes == nil {
                    Text("Enter a positive interval of up to 30 days.")
                        .font(.footnote).foregroundStyle(.orange)
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
