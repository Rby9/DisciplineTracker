import SwiftUI

struct DashboardHeader: View {

    // MARK: - State

    @State private var showProfile = false

    @AppStorage("profile.symbol")
    private var profileSymbol = "person.fill"

    // MARK: - Body

    var body: some View {
        HStack {
            title

            Spacer()

            profileButton
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 24)
        .sheet(isPresented: $showProfile) {
            ProfileView()
        }
    }

    // MARK: - Title

    private var title: some View {
        Text("DisciplineTracker")
            .font(.system(size: 24, weight: .bold))
            .foregroundStyle(.white)
    }

    // MARK: - Profile Button

    private var profileButton: some View {
        Button {
            showProfile = true
        } label: {
            Image(systemName: profileSymbol)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(AppTheme.accent)
                .frame(width: 44, height: 44)
                .background(AppTheme.surface, in: Circle())
                .overlay {
                    Circle()
                        .stroke(
                            AppTheme.border,
                            lineWidth: 2
                        )
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open profile")
    }
}

#Preview {
    DashboardHeader()
}
