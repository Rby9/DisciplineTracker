import SwiftUI

struct DashboardHeader: View {
    
    var body: some View {
        HStack {
            Text("DisciplineTracker")
                .font(
                    .system(
                        size: 24,
                        weight: .bold
                    )
                )
                .foregroundStyle(.white)
            
            Spacer()
            
            Button {
                // Profile - later
            } label: {
                Image(systemName: "person.fill")
                    .font(
                        .system(
                            size: 15,
                            weight: .semibold
                        )
                    )
                    .foregroundStyle(.white)
                    .frame(
                        width: 38,
                        height: 38
                    )
                    .background(
                        Color(hex: "161426")
                    )
                    .overlay {
                        Circle()
                            .stroke(
                                Color(hex: "2E2A4D"),
                                lineWidth: 2
                            )
                    }
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 24)
    }
}
