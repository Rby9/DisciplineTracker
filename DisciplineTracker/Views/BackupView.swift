import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import Foundation

struct BackupDocument: FileDocument {
    nonisolated static var readableContentTypes: [UTType] { [.json] }
    nonisolated let data: Data

    nonisolated init(data: Data) { self.data = data }
    nonisolated init(configuration: ReadConfiguration) throws {
        guard let contents = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        data = contents
    }
    nonisolated func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

struct BackupView: View {
    @Environment(\.modelContext) private var context
    @State private var document: BackupDocument?
    @State private var exporting = false
    @State private var importing = false
    @State private var candidate: TrackerBackup?
    @State private var preview: BackupPreview?
    @State private var restorePreferences = false
    @State private var confirming = false
    @State private var busy = false
    @State private var message = ""
    @State private var showMessage = false
    @AppStorage("backup.lastExport") private var lastExport = 0.0

    var body: some View {
        AppForm {
            Section {
                Text("Save your activities, routines, journal, profile and reminder preferences in a backup file.")
                    .font(.subheadline)
                Button {
                    exportBackup()
                } label: {
                    Label("Export backup", systemImage: "square.and.arrow.up")
                }
                .disabled(busy)
                if lastExport > 0 {
                    LabeledContent("Last export") {
                        Text(Date(timeIntervalSince1970: lastExport), format: .dateTime.day().month(.abbreviated).year().hour().minute())
                    }
                }
            } header: { Text("Backup") } footer: {
                Text("Choose a location in Files, such as iCloud Drive. Backups are manual; they do not sync devices automatically.")
            }
            Section {
                Button {
                    importing = true
                } label: {
                    Label("Choose a backup", systemImage: "square.and.arrow.down")
                }
                .disabled(busy)
                Text("Restore adds missing activities, routines and journal days. Existing records are kept, including their current edits.")
                    .font(.footnote).foregroundStyle(.secondary)
            } header: { Text("Restore") }
            if let candidate, let preview {
                Section("Review backup") {
                    LabeledContent("Backup date") {
                        Text(candidate.createdAt, format: .dateTime.day().month(.abbreviated).year().hour().minute())
                    }
                    LabeledContent("Activities to add", value: String(preview.tasks))
                    LabeledContent("Routines to add", value: String(preview.routines))
                    LabeledContent("Journal days to add", value: String(preview.journal))
                    LabeledContent("Goals to add", value: String(preview.goals))
                    LabeledContent("Existing records kept", value: String(preview.skipped))
                    Toggle("Also restore profile and preferences", isOn: $restorePreferences)
                    if restorePreferences {
                        Text("Your profile name, avatar and notification settings will be replaced by those in this backup.")
                            .font(.footnote).foregroundStyle(.orange)
                        LabeledContent("Name", value: candidate.preferences.name)
                        LabeledContent("Enable all notifications") {
                            Text(LocalizedStringKey(candidate.preferences.notificationsEnabled ? "On" : "Off"))
                        }
                    }
                    Button("Restore missing data") { confirming = true }
                        .disabled(busy || (preview.total == 0 && !restorePreferences))
                    Button("Cancel", role: .cancel) { self.candidate = nil; self.preview = nil }
                    if preview.total == 0 && !restorePreferences {
                        Text("Everything in this backup is already present.")
                            .font(.footnote).foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Backup and restore")
        .fileExporter(isPresented: $exporting, document: document, contentType: .json,
                      defaultFilename: "Ritvara-backup-\(Date().formatted(.iso8601.year().month().day().dateSeparator(.dash)))") { result in
            switch result {
            case .success:
                lastExport = Date().timeIntervalSince1970
                show(String(localized: "Backup exported successfully."))
            case .failure(let error):
                if (error as NSError).code != NSUserCancelledError { show(error.localizedDescription) }
            }
        }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.json], allowsMultipleSelection: false) { result in
            switch result {
            case .success(let urls):
                guard let url = urls.first else { return }
                readBackup(url)
            case .failure(let error):
                if (error as NSError).code != NSUserCancelledError { show(error.localizedDescription) }
            }
        }
        .confirmationDialog("Restore this backup?", isPresented: $confirming, titleVisibility: .visible) {
            Button("Restore missing data") { applyBackup() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(LocalizedStringKey(restorePreferences
                 ? "Missing records will be added and your profile and preferences will be replaced. Existing activities and journal entries stay unchanged."
                 : "Only missing records will be added. Existing data and preferences stay unchanged."))
        }
        .alert("Backup and restore", isPresented: $showMessage) {
            Button("OK", role: .cancel) {}
        } message: { Text(message) }
    }

    private func exportBackup() {
        busy = true
        defer { busy = false }
        do {
            document = BackupDocument(data: try BackupStore.encode(BackupStore.capture(in: context)))
            exporting = true
        } catch { show(error.localizedDescription) }
    }

    private func readBackup(_ url: URL) {
        busy = true
        defer { busy = false }
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        do {
            if let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize, size > BackupStore.maximumBytes {
                throw BackupStore.BackupError.tooLarge
            }
            let backup = try BackupStore.decode(Data(contentsOf: url, options: .mappedIfSafe))
            let counts = try BackupStore.preview(backup, in: context)
            candidate = backup
            preview = counts
            restorePreferences = false
        } catch {
            candidate = nil; preview = nil
            show(error.localizedDescription)
        }
    }

    private func applyBackup() {
        guard let candidate else { return }
        busy = true
        defer { busy = false }
        do {
            // Recalculate at confirmation; a notification action may have changed the store.
            let result = try BackupStore.restore(candidate, in: context)
            if restorePreferences { BackupStore.restorePreferences(candidate.preferences) }
            NotificationManager.shared.refreshNotifications()
            self.candidate = nil
            preview = nil
            show(String(format: String(localized: "Restored %lld records. Existing records were kept."), Int64(result.total)))
        } catch { show(error.localizedDescription) }
    }

    private func show(_ text: String) { message = text; showMessage = true }
}
