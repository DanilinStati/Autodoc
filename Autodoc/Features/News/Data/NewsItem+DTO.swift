import Foundation

nonisolated extension NewsItem {
    init(dto: NewsDTO) {
        self.init(
            id: dto.id,
            title: dto.title.trimmingCharacters(in: .whitespacesAndNewlines),
            summary: dto.description?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "",
            category: dto.categoryType.flatMap { $0.isEmpty ? nil : $0 },
            publishedAt: dto.publishedDate.flatMap(NewsDateParser.date(from:)),
            imageURL: dto.titleImageUrl.flatMap(URL.init(lenient:)),
            articleURL: dto.fullUrl.flatMap(URL.init(lenient:))
        )
    }
}
