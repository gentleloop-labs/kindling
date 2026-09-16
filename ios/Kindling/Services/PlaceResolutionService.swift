@preconcurrency import CoreLocation
import Foundation

struct ResolvedPlace: Sendable {
    let name: String?
    let locality: String?
    let administrativeArea: String?
    let countryCode: String?

    var summary: String? { locality ?? administrativeArea ?? name }
}

actor PlaceResolutionService {
    private var cache: [String: ResolvedPlace] = [:]

    func resolve(latitude: Double, longitude: Double) async -> ResolvedPlace? {
        let key = String(format: "%.3f,%.3f", latitude, longitude)
        if let cached = cache[key] { return cached }
        let geocoder = CLGeocoder()
        guard let placemark = try? await geocoder.reverseGeocodeLocation(
            CLLocation(latitude: latitude, longitude: longitude),
            preferredLocale: .current
        ).first else { return nil }
        let place = ResolvedPlace(
            name: placemark.name,
            locality: placemark.locality,
            administrativeArea: placemark.administrativeArea,
            countryCode: placemark.isoCountryCode
        )
        cache[key] = place
        return place
    }
}
