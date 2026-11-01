import OpenAPIURLSession

enum APIClientFactory {
    static func makeClient() throws -> Client {
        Client(serverURL: try Servers.Server1.url(), transport: URLSessionTransport())
    }

    static func makeStationsService() throws -> StationsListService {
        let configuration = try APIConfiguration.load()
        return StationsListService(client: try makeClient(), apiKey: configuration.apiKey)
    }

    static func makeRoutesService() throws -> ScheduleBetweenStationsService {
        let configuration = try APIConfiguration.load()
        return ScheduleBetweenStationsService(client: try makeClient(), apiKey: configuration.apiKey)
    }
}
