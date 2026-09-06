import SwiftUI

struct MainView: View {

    // MARK: - Environment

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    // MARK: - Properties

    @State private var selectedTab: MainTab = .today
    @State private var showRoutines = false

    private let backgroundColor = Color(hex: "0D0B16")

    // MARK: - Body

    var body: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()

            VStack(spacing: 0) {
                pages
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity
                    )
                    .clipped()

                if selectedTab == .weekly {
                    routinesButton
                        .transition(routinesTransition)
                }

                MainTabBar(selectedTab: $selectedTab)
                    .fixedSize(
                        horizontal: false,
                        vertical: true
                    )
            }
        }
        .preferredColorScheme(.dark)
        .animation(
            .easeInOut(
                duration: reduceMotion ? 0.18 : 0.3
            ),
            value: selectedTab
        )
        .sheet(isPresented: $showRoutines) {
            RoutinesView()
                .preferredColorScheme(.dark)
        }
    }

    // MARK: - Pages

    private var pages: some View {
        ZStack {
            backgroundColor

            todayPage
            weeklyPage
        }
        .background(backgroundColor)
    }

    private var todayPage: some View {
        ContentView()
            .background(backgroundColor)
            .preferredColorScheme(.dark)
            .opacity(
                selectedTab == .today ? 1 : 0
            )
            .offset(
                x: reduceMotion || selectedTab == .today
                    ? 0
                    : -24
            )
            .allowsHitTesting(selectedTab == .today)
            .accessibilityHidden(selectedTab != .today)
            .zIndex(selectedTab == .today ? 1 : 0)
    }

    private var weeklyPage: some View {
        WeeklyView()
            .background(backgroundColor)
            .preferredColorScheme(.dark)
            .opacity(
                selectedTab == .weekly ? 1 : 0
            )
            .offset(
                x: reduceMotion || selectedTab == .weekly
                    ? 0
                    : 24
            )
            .allowsHitTesting(selectedTab == .weekly)
            .accessibilityHidden(selectedTab != .weekly)
            .zIndex(selectedTab == .weekly ? 1 : 0)
    }

    // MARK: - Routines Transition

    private var routinesTransition: AnyTransition {
        if reduceMotion {
            return .opacity
        }

        return .opacity.combined(
            with: .move(edge: .bottom)
        )
    }

    // MARK: - Routines Button

    private var routinesButton: some View {
        Button {
            showRoutines = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "repeat")
                    .font(
                        .system(
                            size: 14,
                            weight: .semibold
                        )
                    )

                Text("Routines")
                    .font(
                        .system(
                            size: 13,
                            weight: .semibold
                        )
                    )

                Spacer()

                Text("Manage")
                    .font(.system(size: 12))

                Image(systemName: "chevron.right")
                    .font(
                        .system(
                            size: 10,
                            weight: .bold
                        )
                    )
            }
            .foregroundStyle(Color(hex: "8B7CFF"))
            .padding(.horizontal, 16)
            .frame(height: 40)
            .background(Color(hex: "161426"))
            .clipShape(
                RoundedRectangle(cornerRadius: 13)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 20)
        .padding(.top, 6)
    }
}
