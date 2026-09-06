import SwiftUI
import Foundation

struct MainView: View {

    // MARK: - Environment

    @Environment(\.accessibilityReduceMotion)
    private var reduceMotion

    // MARK: - Properties

    @State private var selectedTab: MainTab = .today
    @State private var todaySelectedDate = Date()
    @State private var weeklySelectedDate = Date()
    @State private var activeSheet: MainSheet?

    private let backgroundColor = Color(hex: "0D0B16")

    private enum MainSheet: Identifiable {
        case routines
        case journal(Date)

        var id: String {
            switch self {
            case .routines:
                return "routines"
            case .journal(let date):
                return "journal-\(JournalEntry.key(for: date))"
            }
        }
    }

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

                shortcuts

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
        .sheet(item: $activeSheet) { sheet in
            switch sheet {
            case .routines:
                RoutinesView()

            case .journal(let date):
                JournalView(initialDate: date)
            }
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
        ContentView(selectedDate: $todaySelectedDate)
            .background(backgroundColor)
            .preferredColorScheme(.dark)
            .opacity(selectedTab == .today ? 1 : 0)
            .offset(
                x: reduceMotion || selectedTab == .today ? 0 : -24
            )
            .allowsHitTesting(selectedTab == .today)
            .accessibilityHidden(selectedTab != .today)
            .zIndex(selectedTab == .today ? 1 : 0)
    }

    private var weeklyPage: some View {
        WeeklyView(selectedDate: $weeklySelectedDate)
            .background(backgroundColor)
            .preferredColorScheme(.dark)
            .opacity(selectedTab == .weekly ? 1 : 0)
            .offset(
                x: reduceMotion || selectedTab == .weekly ? 0 : 24
            )
            .allowsHitTesting(selectedTab == .weekly)
            .accessibilityHidden(selectedTab != .weekly)
            .zIndex(selectedTab == .weekly ? 1 : 0)
    }

    // MARK: - Shortcuts

    private var shortcuts: some View {
        HStack(spacing: 8) {
            shortcutButton(
                title: "Journal",
                icon: "book.closed"
            ) {
                let date = selectedTab == .today
                    ? todaySelectedDate
                    : weeklySelectedDate

                activeSheet = .journal(date)
            }

            if selectedTab == .weekly {
                shortcutButton(
                    title: "Routines",
                    icon: "repeat"
                ) {
                    activeSheet = .routines
                }
                .transition(.opacity)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 6)
    }

    private func shortcutButton(
        title: String,
        icon: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))

                Text(title)
                    .font(.system(size: 13, weight: .semibold))

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .bold))
            }
            .foregroundStyle(Color(hex: "8B7CFF"))
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .background(Color(hex: "161426"))
            .clipShape(RoundedRectangle(cornerRadius: 13))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
