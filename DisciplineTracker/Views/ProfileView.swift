import SwiftUI
import Foundation

struct ProfileView: View {

    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    // MARK: - Saved Preferences

    @AppStorage("profile.name")
    private var savedName = ""

    @AppStorage("profile.symbol")
    private var savedSymbol = "person.fill"

    // MARK: - Animation

    @Namespace private var avatarAnimation

    private var selectionAnimation: Animation {
        reduceMotion
            ? .easeInOut(duration: 0.15)
            : .spring(
                response: 0.35,
                dampingFraction: 0.8
            )
    }

    // MARK: - Avatar Options

    private let avatars = [
        "person.fill",
        "star.fill",
        "leaf.fill",
        "bolt.fill",
        "flame.fill",
        "heart.fill",
        "moon.fill",
        "sun.max.fill",
        "pawprint.fill",
        "hare.fill",
        "tortoise.fill",
        "bird.fill"
    ]

    private let avatarNames = [
        "Person",
        "Star",
        "Leaf",
        "Lightning",
        "Flame",
        "Heart",
        "Moon",
        "Sun",
        "Paw",
        "Hare",
        "Tortoise",
        "Bird"
    ]

    // MARK: - Display

    private var displayName: String {
        let name = savedName.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        return name.isEmpty ? "Your profile" : name
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            AppForm {
                profilePreview
                nameSection
                avatarSection
                storageSection
            }
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Profile Preview

    private var profilePreview: some View {
        Section {
            VStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(AppTheme.accent.opacity(0.15))

                    Image(systemName: savedSymbol)
                        .font(
                            .system(
                                size: 34,
                                weight: .semibold
                            )
                        )
                        .foregroundStyle(AppTheme.accent)
                        .id(savedSymbol)
                        .transition(
                            reduceMotion
                                ? .opacity
                                : .opacity.combined(
                                    with: .scale(scale: 0.75)
                                )
                        )
                }
                .frame(width: 88, height: 88)
                .animation(
                    selectionAnimation,
                    value: savedSymbol
                )

                Text(displayName)
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)

                Text("Make time for what matters.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
        }
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

    private var avatarSection: some View {
        Section("Choose your avatar") {
            LazyVGrid(
                columns: [
                    GridItem(.adaptive(minimum: 60))
                ],
                spacing: 12
            ) {
                ForEach(avatars.indices, id: \.self) { index in
                    avatarButton(
                        symbol: avatars[index],
                        name: avatarNames[index]
                    )
                }
            }
            .padding(.vertical, 8)
            .animation(
                selectionAnimation,
                value: savedSymbol
            )
        }
    }

    private func avatarButton(
        symbol: String,
        name: String
    ) -> some View {
        let isSelected = savedSymbol == symbol

        return Button {
            guard savedSymbol != symbol else {
                return
            }

            savedSymbol = symbol
        } label: {
            Image(systemName: symbol)
                .font(
                    .system(
                        size: 24,
                        weight: .semibold
                    )
                )
                .foregroundStyle(
                    isSelected ? Color.white : AppTheme.accent
                )
                .scaleEffect(
                    isSelected && !reduceMotion ? 1.12 : 1
                )
                .frame(maxWidth: .infinity)
                .frame(height: 60)
                .background {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(AppTheme.accent.opacity(0.12))

                    if isSelected {
                        selectionBackground
                    }
                }
                .contentShape(
                    RoundedRectangle(cornerRadius: 16)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(name)
        .accessibilityAddTraits(
            isSelected ? .isSelected : []
        )
    }

    @ViewBuilder
    private var selectionBackground: some View {
        if reduceMotion {
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.accent)
        } else {
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.accent)
                .matchedGeometryEffect(
                    id: "selectedAvatar",
                    in: avatarAnimation
                )
        }
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
