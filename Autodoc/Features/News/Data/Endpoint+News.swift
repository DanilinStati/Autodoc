import Foundation

nonisolated extension Endpoint {
    static func news(page: Int, pageSize: Int) -> Endpoint {
        Endpoint(path: "news/\(page)/\(pageSize)")
    }
}
