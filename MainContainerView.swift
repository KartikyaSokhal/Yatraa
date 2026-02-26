
import SwiftUI

struct MainContainerView: View {

    @StateObject private var locationManager     = LocationManager()
    @StateObject private var savedSitesManager   = SavedSitesManager()
    @StateObject private var baseLocationManager = BaseLocationManager()

    @State private var selectedTab: Tab = .explore

    enum Tab {
        case explore, saved
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                tabContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                CustomTabBar(selectedTab: $selectedTab)
            }
            .ignoresSafeArea(edges: .bottom)
        }
        .environmentObject(locationManager)
        .environmentObject(savedSitesManager)
        .environmentObject(baseLocationManager)
    }

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .explore:
            HomeView()
        case .saved:
            SavedView(allSites: sampleSites)
        }
    }
}
