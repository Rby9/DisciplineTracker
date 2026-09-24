import SwiftUI
import Observation

enum AppThemePreset: String, CaseIterable, Identifiable {
    case ritvara
    case ocean
    case forest
    case ember
    case rose

    static let storageKey = "appearance.theme"

    var id: String { rawValue }

    var name: LocalizedStringKey {
        switch self {
        case .ritvara: "Ritvara"
        case .ocean: "Ocean"
        case .forest: "Forest"
        case .ember: "Ember"
        case .rose: "Rose"
        }
    }

    var background: Color {
        switch self {
        case .ritvara: Color(hex: "0D0B16")
        case .ocean: Color(hex: "06131C")
        case .forest: Color(hex: "07140D")
        case .ember: Color(hex: "190C07")
        case .rose: Color(hex: "170A15")
        }
    }

    var surface: Color {
        switch self {
        case .ritvara: Color(hex: "161426")
        case .ocean: Color(hex: "0D2230")
        case .forest: Color(hex: "10251A")
        case .ember: Color(hex: "29150D")
        case .rose: Color(hex: "281222")
        }
    }

    var border: Color {
        switch self {
        case .ritvara: Color(hex: "2E2A4D")
        case .ocean: Color(hex: "20506A")
        case .forest: Color(hex: "28543B")
        case .ember: Color(hex: "63341F")
        case .rose: Color(hex: "5D294E")
        }
    }

    var accent: Color {
        switch self {
        case .ritvara: Color(hex: "8B7CFF")
        case .ocean: Color(hex: "45BFF5")
        case .forest: Color(hex: "4DD58A")
        case .ember: Color(hex: "FF8A4C")
        case .rose: Color(hex: "F472B6")
        }
    }
}

@Observable
@MainActor
final class AppThemeController {
    static let shared = AppThemeController()

    var selected: AppThemePreset {
        didSet {
            UserDefaults.standard.set(
                selected.rawValue,
                forKey: AppThemePreset.storageKey
            )
        }
    }

    private init() {
        let rawValue = UserDefaults.standard.string(forKey: AppThemePreset.storageKey)
        selected = AppThemePreset(rawValue: rawValue ?? "") ?? .ritvara
    }
}

@MainActor
enum AppTheme {
    static var selected: AppThemePreset { AppThemeController.shared.selected }

    static var background: Color { selected.background }
    static var surface: Color { selected.surface }
    static var border: Color { selected.border }
    static var accent: Color { selected.accent }
}
