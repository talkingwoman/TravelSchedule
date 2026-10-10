import Foundation

protocol CarrierServiceProtocol: Sendable {
    func getCarrier(code: String) async throws -> CarrierInfo
}

struct CarrierService: CarrierServiceProtocol {
    let client: Client
    let apiKey: String

    func getCarrier(code: String) async throws -> CarrierInfo {
        let response = try await client.getCarrierInfo(query: .init(apikey: apiKey, code: code))
        switch response {
        case .ok(let success):
            return try success.body.json
        case .undocumented(let status, _):
            throw APIError.httpStatus(status)
        }
    }
}
