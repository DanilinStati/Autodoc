import Foundation

nonisolated enum NetworkError: Error, Equatable, Sendable {
    case offline
    case timedOut
    case transport(URLError.Code)
    case invalidResponse
    case httpStatus(Int)
    case decoding

    init(_ error: URLError) {
        switch error.code {
        case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed, .internationalRoamingOff:
            self = .offline
        case .timedOut:
            self = .timedOut
        default:
            self = .transport(error.code)
        }
    }
}
