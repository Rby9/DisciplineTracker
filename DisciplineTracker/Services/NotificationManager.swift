import Foundation
import UserNotifications

final class NotificationManager {
    
    // MARK: - Singleton
    
    static let shared = NotificationManager()
    
    private init() {}
    
    
    // MARK: - Permission
    
    func requestPermission() {
        UNUserNotificationCenter.current()
            .requestAuthorization(
                options: [
                    .alert,
                    .sound,
                    .badge
                ]
            ) { granted, error in
                
                if granted {
                    print("Notification permission granted")
                    
                } else if let error = error {
                    print(
                        "Notification permission error: \(error.localizedDescription)"
                    )
                }
            }
    }
    
    
    // MARK: - Scheduling
    
    func scheduleNotifications(for task: TaskItem) {
        scheduleReminder(for: task)
        scheduleExactTime(for: task)
        scheduleOverdue(for: task)
    }
    
    
    // MARK: - Reminder Notification
    
    private func scheduleReminder(for task: TaskItem) {
        let content = UNMutableNotificationContent()
        
        content.title = "Reminder"
        content.body = "\(task.title) in 10 minutes"
        content.sound = .default
        
        let reminderTime = Calendar.current.date(
            byAdding: .minute,
            value: -10,
            to: task.startTime
        ) ?? task.startTime
        
        let triggerDate = Calendar.current.dateComponents(
            [.hour, .minute],
            from: reminderTime
        )
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: triggerDate,
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "\(task.id)-reminder",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current()
            .add(request)
    }
    
    
    // MARK: - Exact Time Notification
    
    private func scheduleExactTime(for task: TaskItem) {
        let content = UNMutableNotificationContent()
        
        content.title = "Time for: \(task.title)"
        content.body = "It's time!"
        content.sound = .default
        
        let triggerDate = Calendar.current.dateComponents(
            [.hour, .minute],
            from: task.startTime
        )
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: triggerDate,
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "\(task.id)-exact",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current()
            .add(request)
    }
    
    
    // MARK: - Overdue Notification
    
    private func scheduleOverdue(for task: TaskItem) {
        let content = UNMutableNotificationContent()
        
        content.title = "Overdue"
        content.body = "You still haven't completed: \(task.title)"
        content.sound = .default
        
        let overdueTime = Calendar.current.date(
            byAdding: .minute,
            value: 15,
            to: task.startTime
        ) ?? task.startTime
        
        let triggerDate = Calendar.current.dateComponents(
            [.hour, .minute],
            from: overdueTime
        )
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: triggerDate,
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "\(task.id)-overdue",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current()
            .add(request)
    }
    
    
    // MARK: - Cancellation
    
    func cancelNotifications(for task: TaskItem) {
        let identifiers = [
            "\(task.id)-reminder",
            "\(task.id)-exact",
            "\(task.id)-overdue"
        ]
        
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(
                withIdentifiers: identifiers
            )
    }
}
