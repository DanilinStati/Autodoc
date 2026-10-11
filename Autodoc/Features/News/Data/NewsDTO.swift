import Foundation

nonisolated struct NewsResponseDTO: Decodable, Sendable {
    let news: [NewsDTO]
    let totalCount: Int
}

nonisolated struct NewsDTO: Decodable, Sendable {
    let id: Int
    let title: String
    let description: String?
    let publishedDate: String?
    let url: String?
    let fullUrl: String?
    let titleImageUrl: String?
    let categoryType: String?
}
