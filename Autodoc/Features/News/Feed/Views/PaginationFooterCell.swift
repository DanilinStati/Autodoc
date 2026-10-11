import UIKit

final class PaginationFooterCell: UICollectionViewCell {
    private let spinner = UIActivityIndicatorView(style: .medium)
    private let messageLabel = UILabel()
    private let retryButton = UIButton(configuration: .tinted())
    private lazy var stack = UIStackView(arrangedSubviews: [spinner, messageLabel, retryButton])
    private var onRetry: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureMessageLabel()
        configureRetryButton()
        configureStack()
        layoutStack()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        spinner.stopAnimating()
        onRetry = nil
    }

    func configure(with pagination: NewsFeedViewModel.State.Pagination, onRetry: @escaping () -> Void) {
        self.onRetry = onRetry

        switch pagination {
        case .idle, .loading:
            showLoading()
        case .failed(let message):
            showMessage(message, canRetry: true)
        case .exhausted:
            showMessage(String(localized: "Вы дочитали до конца"), canRetry: false)
        }
    }

    private func showLoading() {
        spinner.isHidden = false
        spinner.startAnimating()
        messageLabel.isHidden = true
        retryButton.isHidden = true
        accessibilityLabel = String(localized: "Загрузка")
    }

    private func showMessage(_ message: String, canRetry: Bool) {
        spinner.stopAnimating()
        spinner.isHidden = true
        messageLabel.text = message
        messageLabel.isHidden = false
        retryButton.isHidden = !canRetry
    }

    private func configureMessageLabel() {
        messageLabel.font = .preferredFont(forTextStyle: .footnote)
        messageLabel.adjustsFontForContentSizeCategory = true
        messageLabel.textColor = .secondaryLabel
        messageLabel.textAlignment = .center
        messageLabel.numberOfLines = 0
    }

    private func configureRetryButton() {
        retryButton.configuration = makeRetryButtonConfiguration()
        retryButton.addAction(UIAction { [weak self] _ in
            self?.onRetry?()
        }, for: .primaryActionTriggered)
    }

    private func makeRetryButtonConfiguration() -> UIButton.Configuration {
        var configuration = UIButton.Configuration.tinted()
        configuration.title = String(localized: "Повторить")
        configuration.image = UIImage(systemName: "arrow.clockwise")
        configuration.imagePadding = Spacing.xs
        configuration.cornerStyle = .capsule
        configuration.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(textStyle: .footnote)
        return configuration
    }

    private func configureStack() {
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = Spacing.s
    }

    private func layoutStack() {
        contentView.addSubviewsForAutoLayout(stack)

        let bottom = stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Spacing.l)
        bottom.priority = .required - 1

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Spacing.l),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Spacing.m),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Spacing.m),
            bottom,
        ])
    }
}
