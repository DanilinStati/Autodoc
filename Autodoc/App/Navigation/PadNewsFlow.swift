import UIKit

@MainActor
final class PadNewsFlow: NewsFlow {

    private let factory: NewsScreenFactory
    private let splitViewController = UISplitViewController(style: .doubleColumn)
    private let detailNavigationController: UINavigationController
    private let compactNavigationController: UINavigationController

    var rootViewController: UIViewController {
        splitViewController
    }

    init(factory: NewsScreenFactory) {
        self.factory = factory
        detailNavigationController = UINavigationController(rootViewController: factory.makeArticlePlaceholder())
        compactNavigationController = UINavigationController(rootViewController: factory.makeFeed())
        configureSplitViewController()
        configureColumns()
    }

    func showArticle(_ item: NewsItem) {
        let article = factory.makeArticle(for: item)

        if splitViewController.isCollapsed {
            compactNavigationController.pushViewController(article, animated: true)
        } else {
            detailNavigationController.setViewControllers([article], animated: false)
        }
    }

    private func configureSplitViewController() {
        splitViewController.preferredDisplayMode = .oneBesideSecondary
        splitViewController.preferredSplitBehavior = .tile
        splitViewController.preferredPrimaryColumnWidthFraction = 0.5
        splitViewController.minimumPrimaryColumnWidth = 360
        splitViewController.maximumPrimaryColumnWidth = 760
    }

    private func configureColumns() {
        splitViewController.setViewController(factory.makeFeed(), for: .primary)
        splitViewController.setViewController(detailNavigationController, for: .secondary)
        splitViewController.setViewController(compactNavigationController, for: .compact)
    }
}
