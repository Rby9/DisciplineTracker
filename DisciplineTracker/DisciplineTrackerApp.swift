import SwiftUI
import SwiftData

@main
struct DisciplineTrackerApp: App {

    // MARK: - Environment

    @Environment(\.scenePhase) private var scenePhase

    // MARK: - Properties

    let modelContainer: ModelContainer

    // MARK: - Initialization

    init() {
        do {
            modelContainer = try ModelContainer(
                for: TaskItem.self,
                TaskSeries.self,
                JournalEntry.self
            )
        } catch {
            fatalError(
                "Could not create ModelContainer: \(error)"
            )
        }

        NotificationManager.shared.configure(
            with: modelContainer.mainContext
        )

        NotificationManager.shared.requestPermission()
    }

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            MainView()
                .task {
                    NotificationManager.shared
                        .refreshNotifications()
                }
                .onChange(of: scenePhase) { _, phase in
                    if phase == .active {
                        NotificationManager.shared
                            .refreshNotifications()
                    }
                }
        }
        .modelContainer(modelContainer)
    }
}
