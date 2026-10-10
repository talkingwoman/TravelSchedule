import Foundation

protocol StationsListServiceProtocol: Sendable {
    func getStations() async throws -> StationsList
}

struct StationsListService: StationsListServiceProtocol {
    let client: Client
    let apiKey: String
    static let maximumResponseBytes = 50 * 1024 * 1024

    func getStations() async throws -> StationsList {
        let response = try await client.getAllStations(query: .init(apikey: apiKey))
        switch response {
        case .ok(let success):
            let data = try await Data(collecting: success.body.html, upTo: Self.maximumResponseBytes)
            return try JSONDecoder().decode(StationsList.self, from: data)
        case .undocumented(let status, _):
            throw APIError.httpStatus(status)
        }
    }
}
