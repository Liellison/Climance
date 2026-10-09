import Foundation
import Combine

@MainActor
final class CitySearchModel: ObservableObject {
    @Published var query = ""
    @Published private(set) var cities: [WeatherCity] = []
    @Published private(set) var reading: WeatherReading?
    @Published private(set) var message: String?
    @Published private(set) var isLoading = false
    @Published private(set) var selectedCityID: Int?

    private let service: WeatherService
    private var request: Task<Void, Never>?
    var canSearch: Bool { query.trimmingCharacters(in: .whitespacesAndNewlines).count >= 2 && !isLoading }

    init(service: WeatherService = WeatherService()) { self.service = service }

    func search() {
        guard canSearch else { return }
        request?.cancel()
        let term = query
        cities = []
        reading = nil
        selectedCityID = nil
        message = nil
        isLoading = true
        request = Task {
            defer { if !Task.isCancelled { isLoading = false } }
            do {
                let results = try await service.cities(matching: term)
                guard !Task.isCancelled else { return }
                cities = results
                if results.count == 1 {
                    selectedCityID = results[0].id
                    let result = try await service.temperature(for: results[0])
                    guard !Task.isCancelled else { return }
                    reading = result
                }
            } catch {
                guard !Task.isCancelled else { return }
                message = Self.errorMessage(error)
            }
        }
    }

    func select(_ city: WeatherCity) {
        request?.cancel()
        selectedCityID = city.id
        message = nil
        reading = nil
        isLoading = true
        request = Task {
            defer { if !Task.isCancelled { isLoading = false } }
            do {
                let result = try await service.temperature(for: city)
                guard !Task.isCancelled else { return }
                reading = result
            } catch {
                guard !Task.isCancelled else { return }
                message = Self.errorMessage(error)
            }
        }
    }

    private static func errorMessage(_ error: Error) -> String {
        if let error = error as? WeatherError { return error.localizedDescription }
        if let error = error as? URLError, error.code == .notConnectedToInternet {
            return "Você está sem conexão. Conecte-se à internet e tente novamente."
        }
        return "Não foi possível consultar o tempo. Tente novamente em instantes."
    }
}
