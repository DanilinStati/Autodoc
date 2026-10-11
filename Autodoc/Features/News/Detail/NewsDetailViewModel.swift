import Foundation

struct NewsDetailViewModel {
    let title: String
    let summary: String?
    let category: String?
    let dateText: String?
    let imageURL: URL?
    let shareURL: URL?

    init(item: NewsItem) {
        title = item.title
        summary = item.summary.isEmpty ? nil : item.summary
        category = item.category
        dateText = item.publishedAt.map { NewsDateFormatter.string(from: $0) }
        imageURL = item.imageURL
        shareURL = item.articleURL
    }
}
