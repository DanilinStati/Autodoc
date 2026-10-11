import Foundation

nonisolated enum NewsFeedSection: Hashable, Sendable {
    case grid
    case footer
}

nonisolated enum NewsFeedItem: Hashable, Sendable {
    case article(NewsItem)
    case placeholder(Int)
    case footer(NewsFeedViewModel.State.Pagination)

    var newsItem: NewsItem? {
        switch self {
        case .article(let item):
            item
        default:
            nil
        }
    }

    var isArticle: Bool {
        if case .article = self {
            return true
        }

        return false
    }
}
