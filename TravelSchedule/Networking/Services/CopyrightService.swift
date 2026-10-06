import Foundation

protocol CopyrightServiceProtocol: Sendable {
    func getCopyright() async throws -> Copyright
}

struct CopyrightService: CopyrightServiceProtocol {
    let client: Client
    let apiKey: String

    func getCopyright() async throws -> Copyright {
        let response = try await client.getCopyright(query: .init(apikey: apiKey))
        switch response {
        case .ok(let success):
            return try success.body.json
        case .undocumented(let status, _):
            throw APIError.httpStatus(status)
        }
    }
}
