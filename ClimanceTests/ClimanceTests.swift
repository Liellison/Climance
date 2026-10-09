import XCTest
@testable import Climance

final class ClimanceTests: XCTestCase {
    private func service() -> WeatherService {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [WeatherProtocol.self]
        return WeatherService(session: URLSession(configuration: configuration))
    }

    func testSearchPreservesAccentsAndReturnsDistinctCities() async throws {
        let cities = try await service().cities(matching: "  São Paulo  ")
        XCTAssertEqual(cities.count, 2)
        XCTAssertEqual(cities[0].displayName, "São Paulo, Brasil")
        XCTAssertNotEqual(cities[0].id, cities[1].id)
    }

    func testEmptySearchDoesNotReachNetwork() async {
        do {
            _ = try await service().cities(matching: " ")
            XCTFail("An empty search should be rejected")
        } catch WeatherError.invalidCity {} catch { XCTFail("Unexpected error: \(error)") }
    }

    func testMissingCityHasRecoverableError() async {
        do {
            _ = try await service().cities(matching: "Missing")
            XCTFail("Expected cityNotFound")
        } catch WeatherError.cityNotFound {} catch { XCTFail("Unexpected error: \(error)") }
    }

    func testWeatherUsesSelectedCityCoordinates() async throws {
        let cities = try await service().cities(matching: "São Paulo")
        let result = try await service().temperature(for: cities[1])
        XCTAssertEqual(result.temperature, -2.5)
        XCTAssertEqual(result.location, cities[1].displayName)
        XCTAssertLessThan(abs(result.updatedAt.timeIntervalSinceNow), 5)
    }

    func testServerFailureDoesNotBecomeWeatherReading() async {
        do {
            _ = try await service().cities(matching: "ServerError")
            XCTFail("Expected unavailable")
        } catch WeatherError.unavailable {} catch { XCTFail("Unexpected error: \(error)") }
    }
}

private final class WeatherProtocol: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        let url = request.url!
        let parameters = URLComponents(url: url, resolvingAgainstBaseURL: false)!.queryItems ?? []
        let query = Dictionary(uniqueKeysWithValues: parameters.map { ($0.name, $0.value ?? "") })
        var status = 200
        let json: String
        if url.host == "geocoding-api.open-meteo.com" {
            switch query["name"] {
            case "São Paulo":
                json = #"{"results":[{"id":1,"name":"São Paulo","admin1":"São Paulo","country":"Brasil","latitude":-23.55,"longitude":-46.63},{"id":2,"name":"São Paulo","country":"Portugal","latitude":40,"longitude":-8}]}"#
            case "Missing": json = "{}"
            case "ServerError": status = 503; json = "{}"
            default: status = 400; json = "{}"
            }
        } else {
            // The selected second city must be used, rather than the first search result.
            if query["latitude"] == "40.0" && query["longitude"] == "-8.0" && query["temperature_unit"] == "celsius" {
                json = #"{"current":{"temperature_2m":-2.5}}"#
            } else { status = 400; json = "{}" }
        }
        client?.urlProtocol(self, didReceive: HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: nil)!, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(json.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
}
