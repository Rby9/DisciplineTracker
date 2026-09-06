import SwiftUI
import SwiftData

struct TaskStatusMenu: ViewModifier {
    @Environment(\.modelContext) private var modelContext
    let task: TaskItem
    @State private var showError = false
    @State private var errorMessage = ""

    func body(content: Content) -> some View {
        content
            .contextMenu {
                ForEach(TaskStatus.allCases.filter { $0 != task.status }) { status in
                    Button {
                        do {
                            try TaskStatusStore.set(status, for: task, in: modelContext)
                        } catch {
                            errorMessage = error.localizedDescription
                            showError = true
                        }
                    } label: {
                        Label("Mark as \(status.rawValue.lowercased())", systemImage: status.symbol)
                    }
                }
            }
            .alert("Could not update task", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: { Text(errorMessage) }
    }
}
