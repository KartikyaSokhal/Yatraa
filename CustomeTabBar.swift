import SwiftUI

struct CustomTabBar: View {
    @Binding var selectedTab: MainContainerView.Tab

    var body: some View {
        HStack(spacing: 0) {
            Spacer()

            CustomTabItem(
                systemImage: selectedTab == .saved ? "bookmark.fill" : "bookmark",
                label: "Saved",
                isSelected: selectedTab == .saved
            ) {
                updateTab(to: .saved)
            }

            Spacer()

            CustomTabItem(
                systemImage: selectedTab == .explore ? "safari.fill" : "safari",
                label: "Explore",
                isSelected: selectedTab == .explore
            ) {
                updateTab(to: .explore)
            }

            Spacer()
        }
        .padding(.vertical, 14)
        .background {
            ZStack {
                Capsule()
                    .fill(.regularMaterial)
                    .shadow(color: .black.opacity(0.25), radius: 15, x: 0, y: 10)
                
                Capsule()
                    .stroke(Color.orange.opacity(0.5), lineWidth: 2)
            }
        }
        .padding(.horizontal, 25)
        .padding(.bottom, 20)
    }

    private func updateTab(to tab: MainContainerView.Tab) {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            selectedTab = tab
        }
    }
}

struct CustomTabItem: View {
    let systemImage: String
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(isSelected ? Color.orange : Color.primary.opacity(0.4))
                    .scaleEffect(isSelected ? 1.2 : 1.0)
                
                Text(label)
                    .font(.system(size: 11, weight: .heavy))
                    .foregroundStyle(isSelected ? Color.blue : Color.primary.opacity(0.4))
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(PlainButtonStyle())
    }
}
