import SwiftUI

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
        .scrollContentBackground(.hidden)
        .background(AppTheme.background)
        .tint(AppTheme.accent)
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
    }
}
