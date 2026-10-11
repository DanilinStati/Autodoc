import Foundation

nonisolated final class RemoteNewsRepository: NewsRepository {
    private let client: APIClient

    init(client: APIClient) {
        self.client = client
    }

    func fetchNews(page: Int, pageSize: Int) async throws -> NewsPage {
        let response = try await client.send(.news(page: page, pageSize: pageSize), as: NewsResponseDTO.self)

        return NewsPage(
            items: response.news.map(NewsItem.init(dto:)),
            totalCount: response.totalCount
        )
    }
}
