import SwiftUI
import Foundation
import SwiftData
import PhotosUI
import UIKit

struct ProfileView: View {

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss

    @Query private var tasks: [TaskItem]

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    // MARK: - Saved Preferences

    @AppStorage("profile.name")
    private var savedName = ""

    @AppStorage("profile.avatarRevision")
    private var avatarRevision = 0

    @AppStorage("profile.photoContentMode")
    private var photoContentMode = "crop"

    @AppStorage(ReminderPreferences.enabledKey)
    private var notificationsEnabled = true

    @AppStorage(LiveActivityPreferences.enabledKey)
    private var liveActivityEnabled = true

    @State private var themeController = AppThemeController.shared

    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var profilePhoto: UIImage?
    @State private var editingPhoto: UIImage?
    @State private var showPhotoEditor = false
    @State private var showPhotoActions = false
    @State private var showPhotoPicker = false
    @State private var showFullPhoto = false
    @State private var showAvatarError = false
    @State private var avatarErrorMessage = ""
    @State private var showNotificationSettings = false

    // MARK: - Animation

    // MARK: - Display

    private var displayName: String {
        let name = savedName.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        return name.isEmpty ? "Your profile" : name
    }

    private var currentWeekTasks: [TaskItem] {
        guard let interval = Calendar.current.dateInterval(of: .weekOfYear, for: .now) else {
            return []
        }
        return tasks.filter { interval.contains($0.startTime) && !$0.isSkipped }
    }

    private var completedThisWeek: [TaskItem] {
        currentWeekTasks.filter(\.isCompleted)
    }

    private var weeklyProgress: Double {
        guard !currentWeekTasks.isEmpty else { return 0 }
        return Double(completedThisWeek.count) / Double(currentWeekTasks.count)
    }

    private var previousWeekTasks: [TaskItem] {
        let calendar = Calendar.current
        guard let current = calendar.dateInterval(of: .weekOfYear, for: .now),
              let previousStart = calendar.date(byAdding: .weekOfYear, value: -1, to: current.start) else {
            return []
        }
        return tasks.filter {
            $0.startTime >= previousStart && $0.startTime < current.start && !$0.isSkipped
        }
    }

    private var previousWeekProgress: Double {
        guard !previousWeekTasks.isEmpty else { return 0 }
        return Double(previousWeekTasks.lazy.filter(\.isCompleted).count) / Double(previousWeekTasks.count)
    }

    private var weeklyDifference: Int {
        Int(((weeklyProgress - previousWeekProgress) * 100).rounded())
    }

    private var completedTotal: Int {
        tasks.lazy.filter(\.isCompleted).count
    }

    private var completionStreaks: (current: Int, best: Int) {
        let calendar = Calendar.current
        let completedDays = Set(tasks.lazy.filter(\.isCompleted).map {
            calendar.startOfDay(for: $0.startTime)
        })
        guard !completedDays.isEmpty else { return (0, 0) }

        let sortedDays = completedDays.sorted()
        var best = 1
        var running = 1

        for index in sortedDays.indices.dropFirst() {
            let previous = sortedDays[sortedDays.index(before: index)]
            let expected = calendar.date(byAdding: .day, value: 1, to: previous)
            running = expected.map { calendar.isDate($0, inSameDayAs: sortedDays[index]) } == true
                ? running + 1
                : 1
            best = max(best, running)
        }

        let today = calendar.startOfDay(for: .now)
        let startingDay = completedDays.contains(today)
            ? today
            : (calendar.date(byAdding: .day, value: -1, to: today) ?? today)
        var current = 0
        var cursor = startingDay
        while completedDays.contains(cursor) {
            current += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }

        return (current, best)
    }

    private var todayTasks: [TaskItem] {
        tasks.filter {
            Calendar.current.isDateInToday($0.startTime) && !$0.isSkipped
        }
    }

    private var completedToday: Int {
        todayTasks.filter(\.isCompleted).count
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            AppForm {
                profilePreview
                nameSection
                themeSection
                notificationDisclosure
                if showNotificationSettings {
                    NotificationSettingsSections()
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    LiveActivitySettingsSection(tasks: tasks)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
                Section {
                    NavigationLink {
                        BackupView()
                    } label: {
                        Label("Backup and restore", systemImage: "externaldrive")
                    }
                }
                storageSection
            }
            .navigationTitle("Profile")
            .task {
                profilePhoto = ProfileAvatarStore.load()
            }
            .onChange(of: selectedPhotoItem) { _, item in
                guard let item else { return }
                Task { await saveSelectedPhoto(item) }
            }
            .photosPicker(
                isPresented: $showPhotoPicker,
                selection: $selectedPhotoItem,
                matching: .images
            )
            .alert("Could not update avatar", isPresented: $showAvatarError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(avatarErrorMessage)
            }
            .sheet(isPresented: $showPhotoEditor) {
                if let editingPhoto {
                    AvatarPhotoEditorView(
                        image: editingPhoto,
                        onUseOriginal: { saveOriginalPhoto(editingPhoto) },
                        onSaveCrop: { zoom, offset, viewport in
                            saveCroppedPhoto(
                                editingPhoto,
                                zoom: zoom,
                                offset: offset,
                                viewport: viewport
                            )
                        }
                    )
                }
            }
            .fullScreenCover(isPresented: $showFullPhoto) {
                if let profilePhoto {
                    ProfilePhotoViewer(image: profilePhoto)
                }
            }
            .confirmationDialog(
                "Profile photo",
                isPresented: $showPhotoActions,
                titleVisibility: .visible
            ) {
                if profilePhoto != nil {
                    Button("View photo") { showFullPhoto = true }
                }
                Button(profilePhoto == nil ? "Choose a photo" : "Change photo") {
                    showPhotoPicker = true
                }
                if profilePhoto != nil {
                    Button("Remove photo", role: .destructive) { removeProfilePhoto() }
                }
                Button("Cancel", role: .cancel) {}
            }
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Notification Disclosure

    private var notificationDisclosure: some View {
        Section {
            Button {
                withAnimation(
                    reduceMotion
                        ? .easeInOut(duration: 0.12)
                        : .spring(response: 0.35, dampingFraction: 0.86)
                ) {
                    showNotificationSettings.toggle()
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "bell.badge.fill")
                        .foregroundStyle(AppTheme.accent)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Notifications and Live Activity")
                            .foregroundStyle(.primary)
                        Text(notificationSummary)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer(minLength: 8)

                    Image(systemName: "chevron.down")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                        .rotationEffect(.degrees(showNotificationSettings ? 180 : 0))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Notifications and Live Activity settings")
            .accessibilityValue(showNotificationSettings ? "Expanded" : "Collapsed")
            .accessibilityHint(showNotificationSettings ? "Double tap to collapse" : "Double tap to expand")
        }
    }

    private var notificationSummary: String {
        let notifications = notificationsEnabled
            ? String(localized: "Notifications on")
            : String(localized: "Notifications paused")
        let liveActivity = liveActivityEnabled
            ? String(localized: "Live Activity on")
            : String(localized: "Live Activity off")
        return "\(notifications) · \(liveActivity)"
    }

    // MARK: - Profile Preview

    private var profilePreview: some View {
        Section {
            VStack(spacing: 18) {
                HStack(spacing: 14) {
                    profilePhotoPreview

                    VStack(alignment: .leading, spacing: 4) {
                        Text(displayName).font(.title2.bold())
                        Text("Your week at a glance")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: 0)
                }

                HStack(spacing: 16) {
                    ProgressRing(progress: weeklyProgress, reloadID: currentWeekTasks.count)
                        .scaleEffect(0.62)
                        .frame(width: 82, height: 82)

                    VStack(alignment: .leading, spacing: 5) {
                        Text("Weekly progress").font(.headline)
                        Text("\(completedThisWeek.count) of \(currentWeekTasks.count) activities completed")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .contentTransition(.numericText())
                        if !previousWeekTasks.isEmpty {
                            Label(
                                weeklyDifference >= 0
                                    ? "\(weeklyDifference)% vs last week"
                                    : "\(abs(weeklyDifference))% below last week",
                                systemImage: weeklyDifference >= 0 ? "arrow.up.right" : "arrow.down.right"
                            )
                            .font(.caption.weight(.medium))
                            .foregroundStyle(weeklyDifference >= 0 ? AppTheme.accent : .orange)
                        }
                    }
                    Spacer(minLength: 0)
                }

                LazyVGrid(
                    columns: [GridItem(.flexible()), GridItem(.flexible())],
                    spacing: 10
                ) {
                    profileStatistics
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
        }
    }

    private var profilePhotoPreview: some View {
        Button {
            if profilePhoto == nil {
                showPhotoPicker = true
            } else {
                showPhotoActions = true
            }
        } label: {
            ZStack {
                Circle().fill(AppTheme.accent.opacity(0.15))
                if let profilePhoto {
                    Image(uiImage: profilePhoto)
                        .resizable()
                        .aspectRatio(contentMode: photoContentMode == "original" ? .fit : .fill)
                        .transition(.opacity)
                } else {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundStyle(AppTheme.accent)
                }
            }
            .frame(width: 70, height: 70)
            .clipShape(Circle())
            .overlay(Circle().stroke(AppTheme.border, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: avatarRevision)
        .accessibilityLabel("Profile photo")
        .accessibilityHint(profilePhoto == nil ? "Double tap to choose a photo" : "Double tap for photo options")
    }

    @ViewBuilder
    private var profileStatistics: some View {
        profileStatistic(value: "\(completedToday)/\(todayTasks.count)", title: "Today", icon: "checkmark.circle.fill")
        profileStatistic(value: "\(completionStreaks.current)", title: "Current streak", icon: "flame.fill")
        profileStatistic(value: "\(completionStreaks.best)", title: "Personal best", icon: "trophy.fill")
        profileStatistic(value: "\(completedTotal)", title: "Completed total", icon: "checkmark.seal.fill")
    }

    private func profileStatistic(value: String, title: LocalizedStringKey, icon: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon).foregroundStyle(AppTheme.accent)
            VStack(alignment: .leading, spacing: 2) {
                Text(value).font(.headline).lineLimit(1).minimumScaleFactor(0.75)
                Text(title).font(.caption).foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(AppTheme.accent.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
    }

    // MARK: - Name

    private var nameSection: some View {
        Section {
            TextField("Your name", text: $savedName)
                .textContentType(.nickname)
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled()
        } header: {
            Text("Name")
        } footer: {
            Text("Your changes save automatically on this device.")
        }
    }

    // MARK: - Avatar

    private var themeSection: some View {
        Section {
            ScrollView(.horizontal) {
                HStack(spacing: 12) {
                    ForEach(AppThemePreset.allCases) { theme in
                        themeButton(theme)
                    }
                }
                .padding(.vertical, 6)
            }
            .scrollIndicators(.hidden)
        } header: {
            Text("Application theme")
        } footer: {
            Text("The selected palette is saved on this device.")
        }
    }

    private func themeButton(_ theme: AppThemePreset) -> some View {
        let isSelected = themeController.selected == theme

        return Button {
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.2)) {
                themeController.selected = theme
            }
        } label: {
            VStack(spacing: 8) {
                ZStack {
                    Circle().fill(theme.background)
                    Circle()
                        .trim(from: 0.08, to: 0.78)
                        .stroke(theme.accent, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Circle()
                        .fill(theme.surface)
                        .frame(width: 20, height: 20)
                }
                .frame(width: 54, height: 54)
                .overlay {
                    Circle().stroke(
                        isSelected ? theme.accent : theme.border,
                        lineWidth: isSelected ? 3 : 1
                    )
                }

                Text(theme.name)
                    .font(.caption.weight(isSelected ? .bold : .regular))
                    .foregroundStyle(isSelected ? theme.accent : .secondary)
            }
            .frame(width: 68)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    @MainActor
    private func saveSelectedPhoto(_ item: PhotosPickerItem) async {
        do {
            guard let data = try await item.loadTransferable(type: Data.self) else {
                throw ProfileAvatarStore.AvatarError.invalidImage
            }
            editingPhoto = try ProfileAvatarStore.saveSource(data)
            showPhotoEditor = true
        } catch {
            avatarErrorMessage = error.localizedDescription
            showAvatarError = true
        }
        selectedPhotoItem = nil
    }

    private func saveOriginalPhoto(_ image: UIImage) {
        do {
            profilePhoto = try ProfileAvatarStore.saveOriginal(image)
            photoContentMode = "original"
            avatarRevision += 1
        } catch {
            presentAvatarError(error)
        }
    }

    private func saveCroppedPhoto(
        _ image: UIImage,
        zoom: CGFloat,
        offset: CGSize,
        viewport: CGFloat
    ) {
        do {
            profilePhoto = try ProfileAvatarStore.saveCrop(
                image,
                zoom: zoom,
                offset: offset,
                viewport: viewport
            )
            photoContentMode = "crop"
            avatarRevision += 1
        } catch {
            presentAvatarError(error)
        }
    }

    private func removeProfilePhoto() {
        do {
            try ProfileAvatarStore.remove()
            profilePhoto = nil
            editingPhoto = nil
            avatarRevision += 1
        } catch {
            presentAvatarError(error)
        }
    }

    private func presentAvatarError(_ error: Error) {
        avatarErrorMessage = error.localizedDescription
        showAvatarError = true
    }

    // MARK: - Storage Information

    private var storageSection: some View {
        Section("Your data") {
            Label(
                "Stored on this device",
                systemImage: "iphone"
            )

            Text(
                "Your profile, tasks and journal are stored locally. "
                + "Sync between devices is not enabled."
            )
            .font(.footnote)
            .foregroundStyle(.secondary)
        }
    }
}

private struct ProfilePhotoViewer: View {
    @Environment(\.dismiss) private var dismiss
    let image: UIImage

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityLabel("Profile photo")

            VStack {
                HStack {
                    Spacer()
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.headline.bold())
                            .foregroundStyle(.white)
                            .frame(width: 44, height: 44)
                            .background(.black.opacity(0.55), in: Circle())
                    }
                    .accessibilityLabel("Close")
                }
                Spacer()
            }
            .padding()
        }
        .preferredColorScheme(.dark)
    }
}
