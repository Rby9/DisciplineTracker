import SwiftUI
import UIKit

struct DashboardHeader: View {

    // MARK: - State

    @State private var showProfile = false

    @AppStorage("profile.avatarRevision")
    private var avatarRevision = 0

    @AppStorage("profile.photoContentMode")
    private var photoContentMode = "crop"

    @State private var profilePhoto: UIImage?

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
        .task(id: avatarRevision) {
            profilePhoto = ProfileAvatarStore.load()
        }
    }

    // MARK: - Title

    private var title: some View {
        Text("Ritvara")
            .font(.system(size: 24, weight: .bold))
            .foregroundStyle(.white)
    }

    // MARK: - Profile Button

    private var profileButton: some View {
        Button {
            showProfile = true
        } label: {
            ZStack {
                Circle().fill(AppTheme.surface)

                if let profilePhoto {
                    Image(uiImage: profilePhoto)
                        .resizable()
                        .aspectRatio(contentMode: photoContentMode == "original" ? .fit : .fill)
                } else {
                    Image(systemName: "person.crop.circle.badge.plus")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(AppTheme.accent)
                }
            }
            .frame(width: 44, height: 44)
            .clipShape(Circle())
            .overlay {
                Circle()
                    .stroke(AppTheme.border, lineWidth: 2)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Open profile")
    }
}

#Preview {
    DashboardHeader()
}
