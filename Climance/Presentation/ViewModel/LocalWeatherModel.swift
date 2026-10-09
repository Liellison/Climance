import SwiftUI
import CoreLocation

// A single location request is enough; there is no background tracking.
@MainActor
final class LocalWeatherModel: NSObject, ObservableObject, @preconcurrency CLLocationManagerDelegate {
    @Published private(set) var reading: WeatherReading?
    @Published private(set) var message: String?
    @Published private(set) var isLoading = false

    private let manager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var started = false
    private var waitingForLocation = false
    private var weatherTask: Task<Void, Never>?
    private var timeoutTask: Task<Void, Never>?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func startIfNeeded() {
        guard !started else { return }
        started = true
        refresh()
    }

    func refresh() {
        guard !isLoading else { return }
        message = nil
        switch manager.authorizationStatus {
        case .notDetermined:
            isLoading = true
            manager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            requestLocation()
        case .denied, .restricted:
            finishWithMessage("Permita o acesso à localização nos Ajustes para ver a temperatura de onde você está. Você também pode consultar outra cidade na busca por cidade.")
        @unknown default:
            finishWithMessage("A localização não está disponível. Use a busca por cidade.")
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard started else { return }
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            if !waitingForLocation && (isLoading || reading == nil) { requestLocation() }
        case .denied, .restricted:
            finishWithMessage("O acesso à localização não foi permitido. Você pode consultar outra cidade na busca por cidade ou permitir o acesso nos Ajustes.")
        default:
            break
        }
    }

    private func requestLocation() {
        isLoading = true
        waitingForLocation = true
        manager.requestLocation()
        timeoutTask?.cancel()
        timeoutTask = Task { @MainActor [weak self] in
            do { try await Task.sleep(nanoseconds: 20_000_000_000) } catch { return }
            guard let self = self, self.waitingForLocation else { return }
            self.finishWithMessage("Não foi possível obter sua localização. Tente atualizar ou use a busca por cidade.")
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard waitingForLocation, let location = locations.last,
              location.horizontalAccuracy >= 0,
              abs(location.timestamp.timeIntervalSinceNow) < 300 else { return }
        waitingForLocation = false
        timeoutTask?.cancel()
        weatherTask = Task { @MainActor in
            var name = "Localização atual"
            if let placemark = try? await geocoder.reverseGeocodeLocation(location).first {
                name = [placemark.locality ?? placemark.subAdministrativeArea,
                        placemark.administrativeArea, placemark.country]
                    .compactMap { $0 }.joined(separator: ", ")
                if name.isEmpty { name = "Localização atual" }
            }
            guard !Task.isCancelled else { return }
            do {
                let result = try await WeatherService().temperature(
                    latitude: location.coordinate.latitude,
                    longitude: location.coordinate.longitude, locationName: name
                )
                guard !Task.isCancelled, isLoading else { return }
                reading = result
                message = nil
                isLoading = false
            } catch {
                guard !Task.isCancelled else { return }
                finishWithMessage("Não foi possível consultar a temperatura da sua localização. Verifique a conexão e tente novamente.")
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        guard waitingForLocation else { return }
        finishWithMessage("Não foi possível obter sua localização. Confira se os Serviços de Localização estão ativados e tente novamente.")
    }

    private func finishWithMessage(_ text: String) {
        timeoutTask?.cancel()
        weatherTask?.cancel()
        geocoder.cancelGeocode()
        waitingForLocation = false
        isLoading = false
        message = text
    }
}
