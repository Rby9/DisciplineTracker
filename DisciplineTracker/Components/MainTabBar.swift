import SwiftUI

enum MainTab: String, CaseIterable {
    case today = "Today"
    case weekly = "Weekly"

    var icon: String {
        switch self {
        case .today:
            return "checklist"
        case .weekly:
            return "calendar"
        }
    }
}

struct MainTabBar: View {

    // MARK: - Environment

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    // MARK: - Properties

    @Binding var selectedTab: MainTab

    @Namespace private var selectionAnimation

    // MARK: - Body

    var body: some View {
        HStack(spacing: 8) {
            ForEach(MainTab.allCases, id: \.self) { tab in
                tabButton(tab)
            }
        }
        .padding(6)
        .background(Color(hex: "161426"))
        .clipShape(
            RoundedRectangle(cornerRadius: 22)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 22)
                .stroke(
                    Color(hex: "2E2A4D"),
                    lineWidth: 1
                )
        }
        .animation(
            reduceMotion
                ? .easeInOut(duration: 0.18)
                : .spring(
                    response: 0.4,
                    dampingFraction: 0.85
                ),
            value: selectedTab
        )
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 8)
    }

    // MARK: - Tab Button

    private func tabButton(_ tab: MainTab) -> some View {
        Button {
            guard selectedTab != tab else {
                return
            }

            selectedTab = tab
        } label: {
            HStack(spacing: 8) {
                Image(systemName: tab.icon)
                    .font(
                        .system(
                            size: 17,
                            weight: .semibold
                        )
                    )

                Text(tab.rawValue)
                    .font(
                        .system(
                            size: 15,
                            weight: .semibold
                        )
                    )
            }
            .foregroundStyle(
                selectedTab == tab
                    ? .white
                    : .white.opacity(0.5)
            )
            .frame(maxWidth: .infinity)
            .frame(height: 46)
            .background {
                if selectedTab == tab {
                    selectionBackground
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(
            selectedTab == tab ? .isSelected : []
        )
    }

    // MARK: - Selection Background

    @ViewBuilder
    private var selectionBackground: some View {
        if reduceMotion {
            RoundedRectangle(cornerRadius: 17)
                .fill(Color(hex: "8B7CFF"))
        } else {
            RoundedRectangle(cornerRadius: 17)
                .fill(Color(hex: "8B7CFF"))
                .matchedGeometryEffect(
                    id: "selectedTab",
                    in: selectionAnimation
                )
        }
    }
}
