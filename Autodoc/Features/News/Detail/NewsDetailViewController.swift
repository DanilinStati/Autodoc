import SafariServices
import UIKit

final class NewsDetailViewController: UIViewController {
    private let viewModel: NewsDetailViewModel
    private let imageLoader: ImageLoader

    private let scrollView = UIScrollView()
    private let imageView = RemoteImageView()
    private let metaLabel = UILabel()
    private let titleLabel = UILabel()
    private let summaryLabel = UILabel()
    private let readButton = UIButton(configuration: .filled())
    private lazy var contentStack = UIStackView(
        arrangedSubviews: [imageView, metaLabel, titleLabel, summaryLabel, readButton]
    )

    init(viewModel: NewsDetailViewModel, imageLoader: ImageLoader) {
        self.viewModel = viewModel
        self.imageLoader = imageLoader
        super.init(nibName: nil, bundle: nil)
        navigationItem.largeTitleDisplayMode = .never
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        configureShareButton()
        configureImageView()
        configureMetaLabel()
        configureTitleLabel()
        configureSummaryLabel()
        configureReadButton()
        configureContentStack()
        layoutScrollView()
        layoutContentStack()
        observeContentSizeChanges()
    }

    // MARK: - Setup

    private func configureShareButton() {
        guard viewModel.shareURL != nil else {
            return
        }

        let share = UIBarButtonItem(systemItem: .action, primaryAction: UIAction { [weak self] _ in
            self?.shareArticle()
        })
        share.accessibilityLabel = String(localized: "Поделиться")
        navigationItem.rightBarButtonItem = share
    }

    private func configureImageView() {
        imageView.layer.cornerRadius = Radius.card
        imageView.layer.cornerCurve = .continuous
        imageView.setImage(viewModel.imageURL, loader: imageLoader)
    }

    private func configureMetaLabel() {
        metaLabel.font = .preferred(.subheadline, weight: .semibold)
        metaLabel.adjustsFontForContentSizeCategory = true
        metaLabel.numberOfLines = 0
        metaLabel.attributedText = NewsMetaText.make(category: viewModel.category, dateText: viewModel.dateText)
        metaLabel.isHidden = viewModel.category == nil && viewModel.dateText == nil
    }

    private func configureTitleLabel() {
        titleLabel.font = .preferred(.title1, weight: .bold)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 0
        titleLabel.accessibilityTraits = .header
        titleLabel.text = viewModel.title
    }

    private func configureSummaryLabel() {
        summaryLabel.numberOfLines = 0
        summaryLabel.isHidden = viewModel.summary == nil
        summaryLabel.attributedText = viewModel.summary.map(makeSummaryText)
    }

    private func makeSummaryText(_ summary: String) -> NSAttributedString {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineHeightMultiple = 1.2

        return NSAttributedString(string: summary, attributes: [
            .font: UIFont.preferredFont(forTextStyle: .body, compatibleWith: traitCollection),
            .foregroundColor: UIColor.label,
            .paragraphStyle: paragraph,
        ])
    }

    private func configureReadButton() {
        readButton.configuration = makeReadButtonConfiguration()
        readButton.isHidden = viewModel.shareURL == nil
        readButton.addAction(UIAction { [weak self] _ in
            self?.openArticle()
        }, for: .primaryActionTriggered)
    }

    private func makeReadButtonConfiguration() -> UIButton.Configuration {
        let titleFont = UIFont.preferred(.headline, weight: .semibold)

        var configuration = UIButton.Configuration.filled()
        configuration.title = String(localized: "Читать на сайте")
        configuration.image = UIImage(systemName: "safari")
        configuration.imagePadding = Spacing.xs
        configuration.buttonSize = .large
        configuration.cornerStyle = .large
        configuration.baseBackgroundColor = .brand
        configuration.baseForegroundColor = .onBrand
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
            var attributes = attributes
            attributes.font = titleFont
            return attributes
        }
        return configuration
    }

    private func configureContentStack() {
        contentStack.axis = .vertical
        contentStack.alignment = .fill
        contentStack.spacing = Spacing.s
        contentStack.setCustomSpacing(Spacing.l, after: imageView)
        contentStack.setCustomSpacing(Spacing.xs, after: metaLabel)
        contentStack.setCustomSpacing(Spacing.s, after: titleLabel)
        contentStack.setCustomSpacing(Spacing.xl, after: summaryLabel)
    }

    private func layoutScrollView() {
        scrollView.alwaysBounceVertical = true
        view.addSubviewsForAutoLayout(scrollView)
        NSLayoutConstraint.activate(scrollView.edgeConstraints(equalTo: view))
    }

    private func layoutContentStack() {
        scrollView.addSubviewsForAutoLayout(contentStack)

        let readable = view.readableContentGuide

        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: Spacing.xs),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -Spacing.xl),
            contentStack.leadingAnchor.constraint(equalTo: readable.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: readable.trailingAnchor),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: NewsCardCell.imageAspectRatio),
        ])
    }

    private func observeContentSizeChanges() {
        registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) { (controller: NewsDetailViewController, _) in
            controller.configureSummaryLabel()
        }
    }

    // MARK: - Actions

    private func openArticle() {
        guard let url = viewModel.shareURL else {
            return
        }

        let safari = SFSafariViewController(url: url)
        safari.preferredControlTintColor = .brand
        safari.dismissButtonStyle = .close
        present(safari, animated: true)
    }

    private func shareArticle() {
        guard let url = viewModel.shareURL, let barButtonItem = navigationItem.rightBarButtonItem else {
            return
        }

        let activity = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        activity.popoverPresentationController?.sourceItem = barButtonItem
        present(activity, animated: true)
    }
}
