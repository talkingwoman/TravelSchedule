import Foundation

protocol RouteStationsServiceProtocol: Sendable {
    func getRoute(uid: String, date: String?) async throws -> RouteStations
}

struct RouteStationsService: RouteStationsServiceProtocol {
    let client: Client
    let apiKey: String

    func getRoute(uid: String, date: String?) async throws -> RouteStations {
        let response = try await client.getRouteStations(query: .init(apikey: apiKey, uid: uid, date: date))
        switch response {
        case .ok(let success):
            return try success.body.json
        case .undocumented(let status, _):
            throw APIError.httpStatus(status)
        }
    }
}
