import UIKit

@MainActor
protocol NewsFlow: AnyObject {
    var rootViewController: UIViewController { get }

    func showArticle(_ item: NewsItem)
}
