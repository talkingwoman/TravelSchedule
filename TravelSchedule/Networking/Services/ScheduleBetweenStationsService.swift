import Foundation

protocol ScheduleBetweenStationsServiceProtocol: Sendable {
    func getSchedule(from: String, to: String, date: String?, transfers: Bool) async throws -> Routes
}

struct ScheduleBetweenStationsService: ScheduleBetweenStationsServiceProtocol {
    let client: Client
    let apiKey: String

    func getSchedule(from: String, to: String, date: String?, transfers: Bool) async throws -> Routes {
        let response = try await client.getScheduleBetweenStations(query: .init(apikey: apiKey, from: from, to: to, date: date, transfers: transfers))
        switch response {
        case .ok(let success):
            return try success.body.json
        case .undocumented(let status, _):
            throw APIError.httpStatus(status)
        }
    }
}
