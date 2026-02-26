import SwiftUI

struct SavedView: View {

    let allSites: [HeritageSite]

    @EnvironmentObject private var savedSitesManager: SavedSitesManager
    @EnvironmentObject private var locationManager: LocationManager

    private var savedSites: [HeritageSite] {
        savedSitesManager.savedSites(from: allSites)
    }

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        NavigationStack {
            Group {
                if savedSites.isEmpty {
                    emptyState
                } else {
                    siteGrid
                }
            }
            .navigationTitle("Saved Sites")
            .background(
                Color(red: 0.96, green: 0.94, blue: 0.91)
                    .ignoresSafeArea()
            )
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.orange.opacity(0.1))
                    .frame(width: 100, height: 100)

                Image(systemName: "bookmark.slash")
                    .font(.system(size: 42))
                    .foregroundColor(.orange.opacity(0.7))
            }

            VStack(spacing: 8) {
                Text("No Saved Sites Yet")
                    .font(.title3)
                    .fontWeight(.semibold)

                Text("Tap the bookmark icon on any heritage site\nto save it for later.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Spacer()
        }
    }

    private var siteGrid: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 20) {

                ForEach(savedSites) { site in
                    NavigationLink(
                        destination: DetailView(site: site)
                    ) {
                        HeritageCard(site: site)
                            .frame(maxWidth: .infinity)
                            .frame(height: 260)  
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 100)
        }
    }
}
