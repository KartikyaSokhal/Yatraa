// HomeView.swift
import SwiftUI

struct HomeView: View {

    @EnvironmentObject private var locationManager:     LocationManager
    @EnvironmentObject private var savedSitesManager:   SavedSitesManager
    @EnvironmentObject private var baseLocationManager: BaseLocationManager

    @State private var selectedCategory: HeritageCategory = .cultural
    @State private var searchText: String = ""
    @State private var isSearching: Bool = false
    @State private var scrollOffset: CGFloat = 0
    @State private var showLocationSheet: Bool = false

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    var filteredSites: [HeritageSite] {
        sampleSites
            .filter { $0.category == selectedCategory }
            .filter {
                searchText.isEmpty ||
                $0.name.localizedCaseInsensitiveContains(searchText)
            }
    }

    var currentSectionTitle: String {
        switch selectedCategory {
        case .cultural: return "Cultural Heritage"
        case .natural:  return "Natural Landscapes"
        case .mixed:    return "Mixed Heritage Sites"
        }
    }

    var body: some View {
        ZStack(alignment: .top) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    heroSection
                    baseLocationStrip
                    contentSection
                }
                .background(
                    GeometryReader { geo in
                        Color.clear
                            .preference(
                                key: ScrollOffsetPreferenceKey.self,
                                value: geo.frame(in: .named("scroll")).minY
                            )
                    }
                )
            }
            .coordinateSpace(name: "scroll")
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { scrollOffset = $0 }

            stickyHeader
        }
        .ignoresSafeArea(edges: .top)
        .sheet(isPresented: $showLocationSheet) {
            ChangeLocationSheet()
                .environmentObject(baseLocationManager)
        }
    }
}

// MARK: - Sections

private extension HomeView {

    var heroSection: some View {
        let heroHeight = UIScreen.main.bounds.height * 0.6
        return ZStack(alignment: .bottomLeading) {
            Image("intro")
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: heroHeight)
                .clipped()

            LinearGradient(
                colors: [Color.black.opacity(0.75), .clear],
                startPoint: .bottom, endPoint: .top
            )

            VStack(alignment: .leading, spacing: 8) {
                Text("Yatraa")
                    .font(.system(size: 42, weight: .bold))
                    .foregroundColor(.white)
                Text("Discover India's Living Heritage — a curated journey through culture, nature, and centuries of legacy.")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.95))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
            .opacity(scrollOffset < -120 ? 0 : 1)
            .animation(.easeInOut(duration: 0.25), value: scrollOffset)
        }
        .frame(height: heroHeight)
    }

    var baseLocationStrip: some View {
        HStack(spacing: 10) {
            Image(systemName: "location.circle.fill")
                .foregroundColor(.orange)
                .font(.subheadline)

            VStack(alignment: .leading, spacing: 1) {
                Text("Planning from")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                Text(baseLocationManager.baseCityName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }

            Spacer()

            Button {
                showLocationSheet = true
            } label: {
                Text("Change")
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.orange.opacity(0.12))
                    .foregroundColor(.orange)
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
        .background(Color(red: 0.96, green: 0.94, blue: 0.91))
    }

    var stickyHeader: some View {
        VStack {
            if scrollOffset < -120 {
                Text("Yatraa")
                    .font(.headline)
                    .fontWeight(.bold)
                    .padding(.top, 55)
                    .padding(.bottom, 12)
                    .frame(maxWidth: .infinity)
                    .background(.ultraThinMaterial)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: scrollOffset)
    }

    var contentSection: some View {
        VStack(alignment: .leading, spacing: 24) {
            headerSection
            categoryButtons
            gridSection
        }
        .frame(maxWidth: .infinity)
        .background(Color(red: 0.96, green: 0.94, blue: 0.91))
    }

    var headerSection: some View {
        HStack(spacing: 12) {
            if isSearching {
                TextField("Search heritage...", text: $searchText)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                Button {
                    withAnimation { isSearching = false; searchText = "" }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            } else {
                Text(currentSectionTitle)
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Button {
                    withAnimation { isSearching = true }
                } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.headline)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
        .animation(.easeInOut, value: isSearching)
    }

    var categoryButtons: some View {
        HStack(spacing: 12) {
            ForEach(HeritageCategory.allCases, id: \.self) { category in
                CategoryButton(
                    title: category.rawValue,
                    isSelected: selectedCategory == category
                ) {
                    selectedCategory = category
                    searchText = ""
                }
            }
        }
        .padding(.horizontal, 20)
    }

    var gridSection: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(filteredSites) { site in
                NavigationLink(destination: DetailView(site: site)) {
                    HeritageCard(site: site)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 100)
    }
}

// MARK: - Change Location Sheet

struct ChangeLocationSheet: View {

    @EnvironmentObject private var baseLocationManager: BaseLocationManager
    @Environment(\.dismiss) private var dismiss

    @State private var cityInput: String = ""
    @State private var latInput:  String = ""
    @State private var lngInput:  String = ""
    @State private var inputError: String? = nil

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    currentLocationCard

                    manualEntrySection

                    resetButton
                }
                .padding()
            }
            .background(Color(red: 0.96, green: 0.94, blue: 0.91).ignoresSafeArea())
            .navigationTitle("Planning Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.semibold)
                        .foregroundColor(.orange)
                }
            }
        }
    }

    private var currentLocationCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Current Base")
                .font(.caption)
                .foregroundColor(.secondary)
            HStack(spacing: 10) {
                Image(systemName: "location.circle.fill")
                    .foregroundColor(.orange)
                    .font(.title3)
                VStack(alignment: .leading, spacing: 2) {
                    Text(baseLocationManager.baseCityName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text(String(format: "%.4f, %.4f",
                                baseLocationManager.baseCoordinate.latitude,
                                baseLocationManager.baseCoordinate.longitude))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .monospacedDigit()
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
    }

    private var manualEntrySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Enter Location")
                .font(.headline)

            VStack(spacing: 12) {
                labeledField("City Name (optional)", placeholder: "e.g. Mumbai", text: $cityInput, keyboard: .default)
                labeledField("Latitude", placeholder: "e.g. 19.0760", text: $latInput, keyboard: .decimalPad)
                labeledField("Longitude", placeholder: "e.g. 72.8777", text: $lngInput, keyboard: .decimalPad)
            }

            if let err = inputError {
                Text(err)
                    .font(.caption)
                    .foregroundColor(.red)
            }

            Button {
                applyManual()
            } label: {
                Text("Set This Location")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(14)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.05), radius: 6, y: 2)
    }

    private func labeledField(_ label: String, placeholder: String, text: Binding<String>, keyboard: UIKeyboardType) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            TextField(placeholder, text: text)
                .keyboardType(keyboard)
                .padding(10)
                .background(Color(.systemGray6))
                .cornerRadius(10)
        }
    }

    private var resetButton: some View {
        Button {
            baseLocationManager.resetToDefault()
            dismiss()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "arrow.counterclockwise")
                Text("Reset to Default (New Delhi)")
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.white)
            .cornerRadius(14)
            .shadow(color: .black.opacity(0.04), radius: 4, y: 1)
        }
    }

    private func applyManual() {
        inputError = nil
        let trimmedLat = latInput.trimmingCharacters(in: .whitespaces)
        let trimmedLng = lngInput.trimmingCharacters(in: .whitespaces)

        guard !trimmedLat.isEmpty, !trimmedLng.isEmpty else {
            inputError = "Latitude and Longitude are required."
            return
        }
        guard let lat = Double(trimmedLat), let lng = Double(trimmedLng) else {
            inputError = "Please enter valid decimal numbers."
            return
        }
        guard lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180 else {
            inputError = "Coordinates out of range. Lat: -90..90, Lng: -180..180"
            return
        }

        baseLocationManager.setManual(cityName: cityInput, latitude: lat, longitude: lng)
        dismiss()
    }
}

// MARK: - Scroll Offset Key

struct ScrollOffsetPreferenceKey: PreferenceKey, Sendable {
    static let defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}
