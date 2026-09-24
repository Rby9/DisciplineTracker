import SwiftUI
import SwiftData

@main
struct DisciplineTrackerApp: App {

    // MARK: - Environment

    @Environment(\.scenePhase) private var scenePhase

    @State private var themeController = AppThemeController.shared

    // MARK: - Properties

    let modelContainer: ModelContainer

    // MARK: - Initialization

    init() {
        do {
            modelContainer = try ModelContainer(
                for: TaskItem.self,
                TaskSeries.self,
                JournalEntry.self,
                Goal.self
            )
        } catch {
            fatalError(
                "Could not create ModelContainer: \(error)"
            )
        }

        NotificationManager.shared.configure(
            with: modelContainer.mainContext
        )
    }

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            MainView()
                .tint(themeController.selected.accent)
                .background(themeController.selected.background)
                .animation(.easeInOut(duration: 0.2), value: themeController.selected)
                .background { NotificationRoutePresenter().frame(width: 0, height: 0) }
                .task {
                    NotificationManager.shared
                        .refreshNotifications()
                    await synchronizeLiveActivity()
                }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active {
                        NotificationManager.shared
                            .refreshNotifications()
                        Task { await synchronizeLiveActivity() }
                    }
                }
        }
        .modelContainer(modelContainer)
    }

    @MainActor
    private func synchronizeLiveActivity() async {
        let descriptor = FetchDescriptor<TaskItem>(
            sortBy: [SortDescriptor(\TaskItem.startTime)]
        )
        let tasks = (try? modelContainer.mainContext.fetch(descriptor)) ?? []
        await RitvaraLiveActivityManager.synchronize(tasks: tasks)
    }
}
