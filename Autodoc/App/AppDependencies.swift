import Foundation

@MainActor
final class AppDependencies {
    
    static let live = AppDependencies.makeLive()

    let newsRepository: NewsRepository
    let imageLoader: ImageLoader

    init(newsRepository: NewsRepository, imageLoader: ImageLoader) {
        self.newsRepository = newsRepository
        self.imageLoader = imageLoader
    }

    private static func makeLive() -> AppDependencies {
        AppDependencies(
            newsRepository: RemoteNewsRepository(client: makeAPIClient()),
            imageLoader: ImageLoader()
        )
    }

    /// Упростил для тестового задания, на проде лучше хранить в конфигах сборки
    private static func makeAPIClient() -> APIClient {
        URLSessionAPIClient(
            baseURL: URL(string: "https://webapi.autodoc.ru/api/")!,
            session: .shared
        )
    }
}
