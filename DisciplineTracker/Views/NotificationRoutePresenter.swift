import SwiftUI
import SwiftData
import UIKit

/// Presents above any existing editor without discarding its unsaved form state.
struct NotificationRoutePresenter: UIViewControllerRepresentable {
    @ObservedObject private var manager = NotificationManager.shared
    @Environment(\.modelContext) private var context

    func makeUIViewController(context: Context) -> RouteController { RouteController() }

    func updateUIViewController(_ controller: RouteController, context: Context) {
        controller.modelContainer = self.context.container
        controller.presentTaskIfNeeded()
    }

    final class RouteController: UIViewController {
        var modelContainer: ModelContainer?
        private var presenting = false

        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            presentTaskIfNeeded()
        }

        func presentTaskIfNeeded() {
            guard !presenting, NotificationManager.shared.openTaskID != nil,
                  let modelContainer else { return }
            presenting = true
            Task { @MainActor [weak self] in
                guard let self else { return }
                defer { self.presenting = false }
                // Wait for cold launch or an in-flight sheet transition, without dismissing forms.
                for _ in 0..<40 {
                    guard let id = NotificationManager.shared.openTaskID else { return }
                    if let window = self.view.window,
                       window.windowScene?.activationState == .foregroundActive,
                       var top = window.rootViewController {
                        while let next = top.presentedViewController { top = next }
                        if !top.isBeingPresented && !top.isBeingDismissed && top.view.window != nil {
                            let host = UIHostingController(rootView:
                                NotificationTaskDestination(taskID: id)
                                    .modelContainer(modelContainer)
                                    .preferredColorScheme(.dark)
                            )
                            host.modalPresentationStyle = .fullScreen
                            NotificationManager.shared.openTaskID = nil
                            top.present(host, animated: true)
                            return
                        }
                    }
                    try? await Task.sleep(for: .milliseconds(250))
                }
            }
        }
    }
}

private struct NotificationTaskDestination: View {
    @Environment(\.dismiss) private var dismiss
    @Query private var tasks: [TaskItem]
    @ObservedObject private var manager = NotificationManager.shared

    init(taskID: UUID) {
        _tasks = Query(filter: #Predicate<TaskItem> { $0.id == taskID })
    }

    var body: some View {
        NavigationStack {
            Group {
                if let task = tasks.first {
                    TaskDetailView(task: task)
                } else {
                    ContentUnavailableView("Activity unavailable", systemImage: "calendar.badge.exclamationmark")
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
        .alert("Notification action", isPresented: Binding(
            get: { manager.lastError != nil },
            set: { _ in manager.clearError() }
        )) {
            Button("OK") { manager.clearError() }
        } message: { Text(manager.lastError ?? "") }
    }
}
