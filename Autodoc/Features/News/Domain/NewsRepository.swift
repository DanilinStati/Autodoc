import Foundation

nonisolated protocol NewsRepository: Sendable {
    func fetchNews(page: Int, pageSize: Int) async throws -> NewsPage
}
