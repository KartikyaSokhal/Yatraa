// BaseLocationManager.swift
// Central source of truth for the user's planning base location.
// Manual entry only — no GPS, no CoreLocation permissions needed.

import Foundation
import CoreLocation

private let defaultCityName  = "New Delhi"
private let defaultLatitude: Double  = 28.6139
private let defaultLongitude: Double = 77.2090

@MainActor
final class BaseLocationManager: ObservableObject {

    @Published private(set) var baseCityName: String
    @Published private(set) var baseCoordinate: CLLocationCoordinate2D

    private let cityKey = "baseLocationCity"
    private let latKey  = "baseLocationLat"
    private let lngKey  = "baseLocationLng"

    init() {
        let storedCity = UserDefaults.standard.string(forKey: "baseLocationCity") ?? ""
        let storedLat  = UserDefaults.standard.double(forKey: "baseLocationLat")
        let storedLng  = UserDefaults.standard.double(forKey: "baseLocationLng")

        if !storedCity.isEmpty && (storedLat != 0 || storedLng != 0) {
            baseCityName   = storedCity
            baseCoordinate = CLLocationCoordinate2D(latitude: storedLat, longitude: storedLng)
        } else {
            baseCityName   = defaultCityName
            baseCoordinate = CLLocationCoordinate2D(latitude: defaultLatitude, longitude: defaultLongitude)
        }
    }



    func setManual(cityName: String, latitude: Double, longitude: Double) {
        let name = cityName.trimmingCharacters(in: .whitespaces)
        baseCityName   = name.isEmpty ? "Custom Location" : name
        baseCoordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        persist()
    }

    func resetToDefault() {
        baseCityName   = defaultCityName
        baseCoordinate = CLLocationCoordinate2D(latitude: defaultLatitude, longitude: defaultLongitude)
        UserDefaults.standard.removeObject(forKey: cityKey)
        UserDefaults.standard.removeObject(forKey: latKey)
        UserDefaults.standard.removeObject(forKey: lngKey)
    }

    func distanceKm(to site: HeritageSite) -> Double {
        let from = CLLocation(latitude: baseCoordinate.latitude, longitude: baseCoordinate.longitude)
        let to   = CLLocation(latitude: site.latitude, longitude: site.longitude)
        let straight = from.distance(from: to) / 1000.0
        return (straight * roadFactor(km: straight)).rounded()
    }

    func formattedDistance(to site: HeritageSite) -> String {
        let km = distanceKm(to: site)
        if km < 1   { return String(format: "%.0f m", km * 1000) }
        if km < 100 { return String(format: "%.1f km", km) }
        return String(format: "%.0f km", km)
    }

    private func roadFactor(km: Double) -> Double {
        if km < 50  { return 1.40 }
        if km < 200 { return 1.30 }
        return 1.25
    }

    private func persist() {
        UserDefaults.standard.set(baseCityName,             forKey: cityKey)
        UserDefaults.standard.set(baseCoordinate.latitude,  forKey: latKey)
        UserDefaults.standard.set(baseCoordinate.longitude, forKey: lngKey)
    }
}
