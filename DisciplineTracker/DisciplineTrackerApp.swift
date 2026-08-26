//
//  DisciplineTrackerApp.swift
//  DisciplineTracker
//
//  Created by Robert Balaban on 22/08/2026.
//

import SwiftUI

@main
struct DisciplineTrackerApp: App {
    init() {
        NotificationManager.shared.requestPermission()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
