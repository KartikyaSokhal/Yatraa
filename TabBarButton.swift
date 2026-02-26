
import SwiftUI

struct TabBarButton: View {

    let systemImage: String
    let label: String
    let isSelected: Bool
    var isCenter: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(isCenter ? .title2 : .body)
                    .foregroundColor(isSelected ? .orange : .gray)
                    .scaleEffect(isSelected ? 1.1 : 1.0)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)

                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(isSelected ? .orange : .gray)
            }
        }
        .frame(minWidth: 60)
    }
}
