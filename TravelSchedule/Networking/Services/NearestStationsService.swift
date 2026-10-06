import Foundation

protocol NearestStationsServiceProtocol: Sendable {
    func getNearestStations(lat: Double, lng: Double, distance: Int) async throws -> NearestStations
}

struct NearestStationsService: NearestStationsServiceProtocol {
    let client: Client
    let apiKey: String

    func getNearestStations(lat: Double, lng: Double, distance: Int) async throws -> NearestStations {
        let response = try await client.getNearestStations(query: .init(apikey: apiKey, lat: lat, lng: lng, distance: distance))
        switch response {
        case .ok(let success):
            return try success.body.json
        case .undocumented(let status, _):
            throw APIError.httpStatus(status)
        }
    }
}
