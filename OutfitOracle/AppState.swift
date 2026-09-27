//
//  AppState.swift
//  OutfitOracle
//
//  App-wide state: which tab is showing, today's weather, and user preferences.
//

import CoreLocation
import Observation
import SwiftUI

enum AppTab: Int {
    case camera = 0, chat, home, closet, profile
}

@Observable
final class AppState {
    var selectedTab: AppTab = .home
    var weather: WeatherSnapshot?
    var weatherStatus: String = "Loading…"

    private let location = LocationFetcher()

    func loadWeather() async {
        guard weather == nil else { return }
        if OutfitOracleApp.isDemo {
            // Fixed chilly day so demos/tests are repeatable and skip the location prompt
            weather = WeatherSnapshot(highC: 9, lowC: 3, symbol: "cloud.sun.fill")
            return
        }
        guard let coordinate = await location.currentCoordinate() else {
            weatherStatus = "Weather off"
            return
        }
        do {
            weather = try await WeatherService.fetch(latitude: coordinate.latitude,
                                                     longitude: coordinate.longitude)
        } catch {
            weatherStatus = "Offline"
        }
    }
}

// MARK: - Preferences (kept in UserDefaults via @AppStorage)
enum PrefKeys {
    static let name = "profileName"
    static let photo = "profilePhoto"
    static let favoriteColors = "favoriteColors"      // comma separated
    static let styles = "favoriteStyles"              // comma separated
    static let checkForTrends = "checkForTrends"
    static let highContrast = "highContrast"
}

extension UserDefaults {
    var favoriteColors: Set<String> {
        Set((string(forKey: PrefKeys.favoriteColors) ?? "")
            .split(separator: ",").map(String.init))
    }
}

// MARK: - Weather (Open-Meteo: free, no API key)
nonisolated enum WeatherService {
    private struct Response: Decodable {
        struct Daily: Decodable {
            let temperature_2m_max: [Double]
            let temperature_2m_min: [Double]
            let weather_code: [Int]
        }
        let daily: Daily
    }

    static func fetch(latitude: Double, longitude: Double) async throws -> WeatherSnapshot {
        let lat = String(format: "%.2f", latitude), lon = String(format: "%.2f", longitude)
        let url = URL(string: "https://api.open-meteo.com/v1/forecast?latitude=\(lat)&longitude=\(lon)&daily=temperature_2m_max,temperature_2m_min,weather_code&timezone=auto&forecast_days=1")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let daily = try JSONDecoder().decode(Response.self, from: data).daily
        return WeatherSnapshot(
            highC: daily.temperature_2m_max.first ?? 0,
            lowC: daily.temperature_2m_min.first ?? 0,
            symbol: symbol(for: daily.weather_code.first ?? 0)
        )
    }

    /// WMO weather code → SF Symbol
    static func symbol(for code: Int) -> String {
        switch code {
        case 0: "sun.max.fill"
        case 1...3: "cloud.sun.fill"
        case 45, 48: "cloud.fog.fill"
        case 51...67: "cloud.rain.fill"
        case 71...77, 85, 86: "cloud.snow.fill"
        case 80...82: "cloud.heavyrain.fill"
        case 95...99: "cloud.bolt.rain.fill"
        default: "cloud.sun.fill"
        }
    }

    /// Shows °F or °C depending on the phone's region
    static func format(_ celsius: Double) -> String {
        Measurement(value: celsius, unit: UnitTemperature.celsius)
            .formatted(.measurement(width: .narrow, usage: .weather, numberFormatStyle: .number.precision(.fractionLength(0))))
    }
}

// MARK: - One-shot location (city-level accuracy is plenty for weather)
final class LocationFetcher: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    private var continuation: CheckedContinuation<CLLocationCoordinate2D?, Never>?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyReduced
    }

    func currentCoordinate() async -> CLLocationCoordinate2D? {
        guard continuation == nil else { return nil }
        return await withCheckedContinuation { continuation in
            self.continuation = continuation
            switch manager.authorizationStatus {
            case .notDetermined:
                manager.requestWhenInUseAuthorization()
            case .authorizedWhenInUse, .authorizedAlways:
                manager.requestLocation()
            default:
                finish(nil)
            }
        }
    }

    private func finish(_ coordinate: CLLocationCoordinate2D?) {
        continuation?.resume(returning: coordinate)
        continuation = nil
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        MainActor.assumeIsolated {
            guard continuation != nil else { return }
            switch status {
            case .authorizedWhenInUse, .authorizedAlways: self.manager.requestLocation()
            case .notDetermined: break
            default: finish(nil)
            }
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let coordinate = locations.last?.coordinate
        MainActor.assumeIsolated { finish(coordinate) }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        MainActor.assumeIsolated { finish(nil) }
    }
}
