import Foundation

nonisolated struct NewsItem: Identifiable, Hashable, Sendable {
    let id: Int
    let title: String
    let summary: String
    let category: String?
    let publishedAt: Date?
    let imageURL: URL?
    let articleURL: URL?
}

nonisolated struct NewsPage: Sendable, Equatable {
    let items: [NewsItem]
    let totalCount: Int
}
