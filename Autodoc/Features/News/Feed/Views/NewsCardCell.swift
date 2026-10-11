import UIKit

final class NewsCardCell: UICollectionViewCell {
    static let imageAspectRatio: CGFloat = 9 / 16
    private static let reservedTitleLines = 3

    private let imageView = RemoteImageView()
    private let titleBox = UIView()
    private let titleLabel = UILabel()
    private lazy var titleMinHeight = titleBox.heightAnchor.constraint(greaterThanOrEqualToConstant: 0)
    private var reservesTitleSpace = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureAccessibility()
        CardAppearance.styleContainer(contentView)
        configureTitleLabel()
        layoutImageView()
        layoutTitle()
        observeContentSizeChanges()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var canBecomeFocused: Bool {
        false
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.cancel()
        imageView.image = nil
    }

    func configure(with item: NewsItem, imagePixelSize: CGFloat, imageLoader: ImageLoader) {
        titleLabel.text = item.title
        accessibilityLabel = item.title
        imageView.setImage(item.imageURL, maxPixelSize: imagePixelSize, loader: imageLoader)
    }

    func setReservesTitleSpace(_ reserves: Bool) {
        guard reservesTitleSpace != reserves else {
            return
        }

        reservesTitleSpace = reserves
        updateReservedTitleHeight()
    }

    private func configureAccessibility() {
        isAccessibilityElement = true
        accessibilityTraits = .button
    }

    private func configureTitleLabel() {
        titleLabel.font = .preferred(.headline, weight: .semibold)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.textColor = .label
        titleLabel.numberOfLines = Self.reservedTitleLines
    }

    private func layoutImageView() {
        contentView.addSubviewsForAutoLayout(imageView)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: Self.imageAspectRatio),
        ])
    }

    private func layoutTitle() {
        contentView.addSubviewsForAutoLayout(titleBox)
        titleBox.addSubviewsForAutoLayout(titleLabel)

        let bottom = titleBox.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Spacing.m)
        bottom.priority = .required - 1

        let hugTitle = titleLabel.bottomAnchor.constraint(equalTo: titleBox.bottomAnchor)
        hugTitle.priority = .defaultLow

        NSLayoutConstraint.activate([
            titleBox.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: Spacing.s),
            titleBox.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Spacing.m),
            titleBox.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Spacing.m),
            bottom,
            titleLabel.topAnchor.constraint(equalTo: titleBox.topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: titleBox.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: titleBox.trailingAnchor),
            titleLabel.bottomAnchor.constraint(lessThanOrEqualTo: titleBox.bottomAnchor),
            hugTitle,
            titleMinHeight,
        ])
    }

    private func observeContentSizeChanges() {
        registerForTraitChanges([UITraitPreferredContentSizeCategory.self]) { (cell: NewsCardCell, _) in
            cell.updateReservedTitleHeight()
        }
    }

    private func updateReservedTitleHeight() {
        let lines = reservesTitleSpace ? CGFloat(Self.reservedTitleLines) : 0
        titleMinHeight.constant = ceil(titleLabel.font.lineHeight * lines)
    }
}
