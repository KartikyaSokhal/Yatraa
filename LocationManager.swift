
import CoreLocation
import Combine

@MainActor
final class LocationManager: NSObject, ObservableObject {

    // MARK: - Published State
    @Published private(set) var userLocation: CLLocation?
    @Published private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published private(set) var locationError: LocationError?

    // MARK: - Private
    nonisolated(unsafe) private let manager: CLLocationManager

    // MARK: - Init
    override init() {
        manager = CLLocationManager()
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        manager.distanceFilter = 100
        authorizationStatus = manager.authorizationStatus
    }

   

    func requestLocationPermission() {
        switch manager.authorizationStatus {
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            locationError = .permissionDenied
        case .authorizedWhenInUse, .authorizedAlways:
            startUpdating()
        @unknown default:
            break
        }
    }

    func startUpdating() {
        guard manager.authorizationStatus == .authorizedWhenInUse ||
              manager.authorizationStatus == .authorizedAlways else { return }
        manager.startUpdatingLocation()
    }

    func stopUpdating() {
        manager.stopUpdatingLocation()
    }

  
    func distanceInKm(to site: HeritageSite) -> Double? {
        guard let userLocation else { return nil }
        let siteLocation = CLLocation(latitude: site.latitude, longitude: site.longitude)
        return userLocation.distance(from: siteLocation) / 1000.0
    }


    func distanceInKm(from coordinate: CLLocationCoordinate2D, to site: HeritageSite) -> Double {
        let from = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let to = CLLocation(latitude: site.latitude, longitude: site.longitude)
        return from.distance(from: to) / 1000.0
    }

    func distanceString(to site: HeritageSite) -> String {
        guard let km = distanceInKm(to: site) else { return "Location unavailable" }
        return formatKm(km)
    }

    func distanceString(from coordinate: CLLocationCoordinate2D, to site: HeritageSite) -> String {
        let km = distanceInKm(from: coordinate, to: site)
        return formatKm(km)
    }

    private func formatKm(_ km: Double) -> String {
        if km < 1.0 {
            return String(format: "%.0f m", km * 1000)
        } else if km < 100 {
            return String(format: "%.1f km", km)
        } else {
            return String(format: "%.0f km", km)
        }
    }

   
    enum LocationError: LocalizedError {
        case permissionDenied
        case locationUnavailable

        var errorDescription: String? {
            switch self {
            case .permissionDenied: return "Location permission denied. Enable in Settings."
            case .locationUnavailable: return "Unable to determine your location."
            }
        }
    }
}


extension LocationManager: CLLocationManagerDelegate {

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
       
        let status = manager.authorizationStatus
        Task { @MainActor in
            self.authorizationStatus = status
            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                self.locationError = nil
                self.startUpdating()
            case .denied, .restricted:
                self.locationError = .permissionDenied
                self.userLocation = nil
            default:
                break
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let latest = locations.last,
              latest.horizontalAccuracy >= 0,
              latest.horizontalAccuracy < 500,
              latest.timestamp.timeIntervalSinceNow > -30
        else { return }

        Task { @MainActor in
            self.userLocation = latest
            self.locationError = nil
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            if let clError = error as? CLError, clError.code == .denied {
                self.locationError = .permissionDenied
            } else {
                self.locationError = .locationUnavailable
            }
        }
    }
}
