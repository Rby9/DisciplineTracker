import SwiftUI
import UIKit

struct AppForm<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        Form {
            content
                .listRowBackground(AppTheme.surface)
                .listRowSeparatorTint(AppTheme.border)
        }
        .scrollDismissesKeyboard(.interactively)
        .scrollContentBackground(.hidden)
        .background(AppTheme.background)
        .tint(AppTheme.accent)
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }
            }
        }
    }
}
