import UIKit

@MainActor
final class PhoneNewsFlow: NewsFlow {

    private let factory: NewsScreenFactory
    private let navigationController: UINavigationController

    var rootViewController: UIViewController {
        navigationController
    }

    init(factory: NewsScreenFactory) {
        self.factory = factory
        navigationController = UINavigationController(rootViewController: factory.makeFeed())
    }

    func showArticle(_ item: NewsItem) {
        navigationController.pushViewController(factory.makeArticle(for: item), animated: true)
    }
}
