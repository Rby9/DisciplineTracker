import SwiftUI

struct ContentView: View {
    let sampleTask = TaskItem(
        id: UUID(),
        title: "Sala dimineata",
        category: .gym,
        startTime: Date(),
        isCompleted: false,
        notes: ""
    )
    
    var body: some View {
        VStack(spacing: 16 ) {
            Text(sampleTask.title)
                .font(.title)
            Text(sampleTask.category.rawValue)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}
#Preview{
    ContentView()
}
