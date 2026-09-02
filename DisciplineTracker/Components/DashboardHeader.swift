import SwiftUI

struct DashboardHeader: View {
    
    // MARK: - Body
    
    var body: some View {
        HStack {
            title
            
            Spacer()
            
            profileButton
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 24)
    }
    
    
    // MARK: - View Components
    
    private var title: some View {
        Text("DisciplineTracker")
            .font(
                .system(
                    size: 24,
                    weight: .bold
                )
            )
            .foregroundStyle(.white)
    }
    
    private var profileButton: some View {
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
}


#Preview {
    DashboardHeader()
}
