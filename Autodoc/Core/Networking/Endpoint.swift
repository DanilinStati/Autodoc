import Foundation

nonisolated struct Endpoint: Sendable, Equatable {
    nonisolated enum Method: String, Sendable {
        case get = "GET"
    }

    let path: String
    var method: Method = .get
    var timeout: TimeInterval = 15

    func urlRequest(relativeTo baseURL: URL) -> URLRequest {
        var request = URLRequest(url: baseURL.appending(path: path), timeoutInterval: timeout)
        request.httpMethod = method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        return request
    }
}
