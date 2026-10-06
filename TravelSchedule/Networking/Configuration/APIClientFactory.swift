import OpenAPIURLSession

enum APIClientFactory {
    static func makeClient() throws -> Client {
        Client(serverURL: try Servers.Server1.url(), transport: URLSessionTransport())
    }
}
