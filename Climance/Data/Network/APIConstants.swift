import Foundation

struct WeatherReading {
    let location: String
    let temperature: Double
    var updatedAt: Date = Date()
}

struct WeatherService {
    var session: URLSession = .shared

    func cities(matching query: String) async throws -> [WeatherCity] {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard query.count >= 2 else { throw WeatherError.invalidCity }
        let response: LocationResponse = try await fetch(
            "https://geocoding-api.open-meteo.com/v1/search",
            parameters: ["name": query, "count": "8", "language": "pt"]
        )
        let cities = response.results ?? []
        guard !cities.isEmpty else { throw WeatherError.cityNotFound }
        return cities
    }

    func temperature(for city: WeatherCity) async throws -> WeatherReading {
        try await temperature(latitude: city.latitude, longitude: city.longitude, locationName: city.displayName)
    }

    func temperature(latitude: Double, longitude: Double, locationName: String) async throws -> WeatherReading {
        let forecast: ForecastResponse = try await fetch(
            "https://api.open-meteo.com/v1/forecast",
            parameters: [
                "latitude": String(latitude), "longitude": String(longitude),
                "current": "temperature_2m", "temperature_unit": "celsius"
            ]
        )
        return WeatherReading(location: locationName, temperature: forecast.current.temperature)
    }

    private func fetch<Response: Decodable>(
        _ endpoint: String, parameters: [String: String]
    ) async throws -> Response {
        guard var components = URLComponents(string: endpoint) else {
            throw WeatherError.unavailable
        }
        components.queryItems = parameters.map { URLQueryItem(name: $0.key, value: $0.value) }
        guard let url = components.url else { throw WeatherError.unavailable }
        var request = URLRequest(url: url)
        request.timeoutInterval = 20
        let (data, response) = try await session.data(for: request)
        guard let response = response as? HTTPURLResponse,
              (200..<300).contains(response.statusCode) else {
            throw WeatherError.unavailable
        }
        return try JSONDecoder().decode(Response.self, from: data)
    }
}

struct WeatherCity: Decodable, Identifiable {
    let id: Int
    let name: String
    let admin1: String?
    let country: String?
    let latitude: Double
    let longitude: Double

    var region: String {
        [admin1, country].compactMap { $0 }.filter { !$0.isEmpty && $0 != name }.joined(separator: ", ")
    }
    var displayName: String { region.isEmpty ? name : "\(name), \(region)" }
}

private struct LocationResponse: Decodable {
    let results: [WeatherCity]?
}

private struct ForecastResponse: Decodable {
    let current: Current

    struct Current: Decodable {
        let temperature: Double

        enum CodingKeys: String, CodingKey {
            case temperature = "temperature_2m"
        }
    }
}

enum WeatherError: LocalizedError {
    case invalidCity
    case cityNotFound
    case unavailable

    var errorDescription: String? {
        switch self {
        case .invalidCity:
            return "Digite pelo menos duas letras para buscar uma cidade."
        case .cityNotFound:
            return "Cidade não encontrada. Confira o nome e tente novamente."
        case .unavailable:
            return "O serviço de tempo está indisponível. Tente novamente em instantes."
        }
    }
}
