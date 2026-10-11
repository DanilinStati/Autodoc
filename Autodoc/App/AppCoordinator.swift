import Combine
import UIKit

@MainActor
final class AppCoordinator {

    private let window: UIWindow
    private let dependencies: AppDependencies
    private var flow: NewsFlow?
    private var cancellables = Set<AnyCancellable>()

    init(window: UIWindow, dependencies: AppDependencies) {
        self.window = window
        self.dependencies = dependencies
    }

    func start() {
        let feedViewModel = NewsFeedViewModel(repository: dependencies.newsRepository)
        let factory = NewsScreenFactory(feedViewModel: feedViewModel, imageLoader: dependencies.imageLoader)
        let flow = makeFlow(factory: factory)

        bindSelection(of: feedViewModel, to: flow)
        self.flow = flow

        window.rootViewController = flow.rootViewController
        window.makeKeyAndVisible()
    }

    private func makeFlow(factory: NewsScreenFactory) -> NewsFlow {
        switch UIDevice.current.userInterfaceIdiom {
        case .pad:
            return PadNewsFlow(factory: factory)
        default:
            return PhoneNewsFlow(factory: factory)
        }
    }

    private func bindSelection(of viewModel: NewsFeedViewModel, to flow: NewsFlow) {
        viewModel.selection
            .sink { [weak flow] item in
                flow?.showArticle(item)
            }
            .store(in: &cancellables)
    }
}
