
import SwiftUI

struct HeritageCard: View {

    let site: HeritageSite

    @EnvironmentObject private var baseLocationManager: BaseLocationManager
    @EnvironmentObject private var savedSitesManager: SavedSitesManager

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {

            Image(site.images.first ?? "placeholder")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(maxWidth: 180)
                .frame(height: 150)
                .clipped()
                .cornerRadius(12, corners: [.topLeft, .topRight])

            VStack(alignment: .leading, spacing: 6) {

                Text(site.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 4) {
                    Image(systemName: "mappin.circle.fill")
                        .foregroundColor(.orange)
                        .font(.caption2)
                    Text(baseLocationManager.formattedDistance(to: site))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)

                    Spacer(minLength: 4)

                    Button {
                        savedSitesManager.toggleSave(site)
                    } label: {
                        Image(systemName: savedSitesManager.isSaved(site) ? "bookmark.fill" : "bookmark")
                            .font(.caption)
                            .foregroundColor(savedSitesManager.isSaved(site) ? .orange : .gray)
                            .animation(.spring(response: 0.3, dampingFraction: 0.5), value: savedSitesManager.isSaved(site))
                    }
                    .buttonStyle(.plain)
                }

                Text(site.location)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .padding(10)
        }
        .background(Color(.systemBackground))
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 2)
    }
}


extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat
    var corners: UIRectCorner

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
