import Foundation

struct APIConfiguration {
    let apiKey: String

    init(apiKey: String) throws {
        let value = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty, value != "YOUR_API_KEY", !value.contains("$(") else {
            throw ConfigurationError.missingAPIKey
        }
        self.apiKey = value
    }

    static func load(from bundle: Bundle = .main) throws -> APIConfiguration {
        try APIConfiguration(apiKey: bundle.object(forInfoDictionaryKey: "YandexRaspAPIKey") as? String ?? "")
    }
}

enum ConfigurationError: Error {
    case missingAPIKey
}
