//
//  DisciplineTrackerApp.swift
//  DisciplineTracker
//
//  Created by Robert Balaban on 22/08/2026.
//

import SwiftUI
import SwiftData

@main
struct DisciplineTrackerApp: App {
    
    let modelContainer: ModelContainer
    
    init() {
        
        do {
            modelContainer = try ModelContainer(for: TaskItem.self)
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
        
        NotificationManager.shared.requestPermission()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(modelContainer)
    }
}
