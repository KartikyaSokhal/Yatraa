// DetailView.swift
import SwiftUI
import CoreLocation

struct DetailView: View {

    let site: HeritageSite

    @EnvironmentObject private var savedSitesManager: SavedSitesManager
    @EnvironmentObject private var locationManager: LocationManager
    @Environment(\.dismiss) private var dismiss

    @State private var bookmarkBounce: Bool = false

    // MARK: - Reactive save state — reads directly from manager
    private var isSaved: Bool {
        savedSitesManager.isSaved(site)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // MARK: Hero Image
                Image(site.images.first ?? "placeholder")
                    .resizable()
                    .scaledToFill()
                    .frame(height: 320)
                    .frame(maxWidth: 365)
                    .clipped()
                    .cornerRadius(28)
                    .padding(.horizontal)
                    .padding(.top, 12)

                // MARK: Title Block
                VStack(alignment: .leading, spacing: 6) {
                    Text(site.category.rawValue.uppercased())
                        .font(.caption)
                        .foregroundColor(.orange)
                        .fontWeight(.medium)

                    Text(site.name)
                        .font(.title)
                        .fontWeight(.bold)

                    Text(site.location)
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    distanceLabel
                }
                .padding(.horizontal)

                Divider().padding(.horizontal)

                // MARK: History
                InfoSection(title: "History & Origin", content: site.history)
                    .padding(.horizontal)

                // MARK: Key Highlights
                VStack(alignment: .leading, spacing: 14) {
                    Text("Key Highlights")
                        .font(.headline)

                    ForEach(site.keyFeatures, id: \.self) { feature in
                        HStack(spacing: 10) {
                            Image(systemName: "sparkle")
                                .foregroundColor(.orange)
                            Text(feature)
                                .font(.subheadline)
                        }
                    }
                }
                .padding()
                .background(Color.white)
                .cornerRadius(20)
                .shadow(color: .black.opacity(0.05), radius: 6, y: 4)
                .padding(.horizontal)

                // MARK: UNESCO
                InfoSection(title: "Why UNESCO Recognised This Site", content: site.unescoReason)
                    .padding(.horizontal)

                // MARK: Action Buttons
                HStack(spacing: 16) {
                    NavigationLink(destination: PlannerView(site: site)) {
                        Text("Plan My Visit")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(18)
                    }

                    Button {
                        toggleSave()
                    } label: {
                        Image(systemName: isSaved ? "bookmark.fill" : "bookmark")
                            .font(.title3)
                            .foregroundColor(isSaved ? .orange : .gray)
                            .frame(width: 50, height: 50)
                            .background(Color.white)
                            .cornerRadius(14)
                            .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
                            .scaleEffect(bookmarkBounce ? 1.25 : 1.0)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 30)
            }
        }
        .background(
            Color(red: 0.96, green: 0.94, blue: 0.91).ignoresSafeArea()
        )
        .navigationBarTitleDisplayMode(.inline)
    }


    @ViewBuilder
    private var distanceLabel: some View {
        if let km = locationManager.distanceInKm(to: site) {
            HStack(spacing: 4) {
                Image(systemName: "location.fill")
                    .font(.caption)
                        .foregroundColor(.orange)
                Text(locationManager.distanceString(to: site) + " away from you")
                    .font(.caption)
                        .foregroundColor(.orange)
            }
        } else if let error = locationManager.locationError {
            Text(error.localizedDescription)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }


    private func toggleSave() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            bookmarkBounce = true
        }
        // Reset scale after bounce
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                bookmarkBounce = false
            }
        }
        savedSitesManager.toggleSave(site)
    }
}



struct InfoSection: View {
    let title: String
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
            Text(content)
                .font(.body)
                .lineSpacing(4)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 8, y: 4)
    }
}
