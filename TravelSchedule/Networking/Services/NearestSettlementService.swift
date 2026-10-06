import Foundation

protocol NearestSettlementServiceProtocol: Sendable {
    func getNearestSettlement(lat: Double, lng: Double) async throws -> NearestSettlement
}

struct NearestSettlementService: NearestSettlementServiceProtocol {
    let client: Client
    let apiKey: String

    func getNearestSettlement(lat: Double, lng: Double) async throws -> NearestSettlement {
        let response = try await client.getNearestCity(query: .init(apikey: apiKey, lat: lat, lng: lng))
        switch response {
        case .ok(let success):
            return try success.body.json
        case .undocumented(let status, _):
            throw APIError.httpStatus(status)
        }
    }
}
