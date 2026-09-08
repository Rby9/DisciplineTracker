import SwiftUI
import UserNotifications

struct NotificationSettingsSections: View {
    @Environment(\.scenePhase) private var scenePhase
    @ObservedObject private var manager = NotificationManager.shared
    @AppStorage(ReminderPreferences.enabledKey) private var enabled = true
    @State private var defaults = ReminderPreferences.defaultOffsets
    @State private var testing = false
    @State private var testMessage: String?

    var body: some View {
        Section {
            Toggle("Enable all notifications", isOn: $enabled)
                .onChange(of: enabled) { _, value in
                    testMessage = nil
                    if value { manager.requestPermission() }
                    manager.refreshNotifications()
                }
            LabeledContent("Permission") { Text(manager.permissionLabel) }
            if manager.authorizationStatus == .notDetermined {
                Button("Allow notifications") { manager.requestPermission() }
            } else {
                Button("Open notification settings") { manager.openSettings() }
            }
            Button("Test notifications") {
                testing = true
                testMessage = nil
                Task {
                    do {
                        try await manager.scheduleTest()
                        testMessage = String(localized: "Test scheduled in 5 seconds. You can lock your screen.")
                    } catch {
                        testMessage = error.localizedDescription
                    }
                    testing = false
                }
            }
            .disabled(!enabled || testing)
            if let testMessage { Text(testMessage).font(.footnote) }
            if let error = manager.lastError {
                Text(error).font(.footnote).foregroundStyle(.orange)
                Button("Retry scheduling") { manager.refreshNotifications() }
            }
            if manager.deferredCount > 0 {
                Text("Some later reminders are not scheduled yet. Open the app regularly to schedule the next ones.")
                    .font(.footnote).foregroundStyle(.orange)
                if let date = manager.scheduledThrough {
                    LabeledContent("Last scheduled reminder") {
                        Text(date, format: .dateTime.day().month(.abbreviated).hour().minute())
                    }
                }
            }
        } header: {
            Text("Notification settings")
        } footer: {
            Text("Pausing keeps your choices. Focus, Silent mode and Scheduled Summary may affect alerts and sounds.")
        }
        ReminderOptionsSection(offsets: $defaults, title: "Defaults for new activities", toggleTitle: "Use default reminders")
            .onChange(of: defaults) { _, value in
                ReminderPreferences.defaultOffsets = value
            }
        Section {
            Text("Default reminders apply only to new activities and routines. Existing activities keep their choices.")
                .font(.footnote).foregroundStyle(.secondary)
        }
        .task { await manager.updateAuthorizationStatus() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                Task { await manager.updateAuthorizationStatus() }
            }
        }
    }
}
