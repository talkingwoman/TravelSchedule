import Foundation

protocol StationScheduleServiceProtocol: Sendable {
    func getSchedule(station: String, date: String?) async throws -> StationSchedule
}

struct StationScheduleService: StationScheduleServiceProtocol {
    let client: Client
    let apiKey: String

    func getSchedule(station: String, date: String?) async throws -> StationSchedule {
        let response = try await client.getStationSchedule(query: .init(apikey: apiKey, station: station, date: date))
        switch response {
        case .ok(let success):
            return try success.body.json
        case .undocumented(let status, _):
            throw APIError.httpStatus(status)
        }
    }
}
