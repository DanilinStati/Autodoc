import UIKit

@MainActor
final class NewsScreenFactory {

    private let feedViewModel: NewsFeedViewModel
    private let imageLoader: ImageLoader

    init(feedViewModel: NewsFeedViewModel, imageLoader: ImageLoader) {
        self.feedViewModel = feedViewModel
        self.imageLoader = imageLoader
    }

    func makeFeed() -> UIViewController {
        NewsFeedViewController(viewModel: feedViewModel, imageLoader: imageLoader)
    }

    func makeArticle(for item: NewsItem) -> UIViewController {
        NewsDetailViewController(viewModel: NewsDetailViewModel(item: item), imageLoader: imageLoader)
    }

    func makeArticlePlaceholder() -> UIViewController {
        NewsDetailPlaceholderViewController()
    }
}
