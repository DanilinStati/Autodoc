import UIKit

final class NewsDetailPlaceholderViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        contentUnavailableConfiguration = UIContentUnavailableConfiguration.articleNotSelected()
    }
}
