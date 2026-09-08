import Foundation

/// Positive offsets are minutes before the task. -15 is retained for legacy tasks only.
enum ReminderPolicy {
    static let legacyOffsets = [10, 0, -15]
    static let presets = [0, 5, 10, 15, 20, 30, 60]
    static let maximumMinutes = 43_200 // 30 days

    static func normalized(_ offsets: [Int]) -> [Int] {
        Array(Set(offsets.filter { $0 == -15 || (0...maximumMinutes).contains($0) }))
            .sorted(by: >)
    }

    static func fireDate(start: Date, offset: Int) -> Date {
        start.addingTimeInterval(-Double(offset) * 60)
    }

    static func label(_ offset: Int) -> String {
        if offset == 0 { return String(localized: "At the start") }
        if offset == -15 { return String(localized: "15 minutes after (existing reminder)") }
        return String(format: String(localized: "%lld minutes before"), Int64(offset))
    }
}

enum ReminderPreferences {
    static let enabledKey = "reminders.enabled"
    static let defaultsKey = "reminders.defaultOffsets"

    static var enabled: Bool {
        (UserDefaults.standard.object(forKey: enabledKey) as? Bool) ?? true
    }

    static var defaultOffsets: [Int] {
        get {
            guard let data = UserDefaults.standard.data(forKey: defaultsKey),
                  let values = try? JSONDecoder().decode([Int].self, from: data) else { return [10] }
            return ReminderPolicy.normalized(values.filter { $0 >= 0 })
        }
        set {
            let values = ReminderPolicy.normalized(newValue.filter { $0 >= 0 })
            UserDefaults.standard.set(try? JSONEncoder().encode(values), forKey: defaultsKey)
        }
    }
}
