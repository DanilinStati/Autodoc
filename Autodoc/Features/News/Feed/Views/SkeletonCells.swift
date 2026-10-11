import UIKit

final class NewsCardSkeletonCell: UICollectionViewCell {
    private static let lineHeight: CGFloat = 14

    private let imagePlaceholder = ShimmerView()
    private let firstLine = ShimmerView.line()
    private let secondLine = ShimmerView.line()

    override init(frame: CGRect) {
        super.init(frame: frame)
        isAccessibilityElement = false
        CardAppearance.styleContainer(contentView)
        contentView.addSubviewsForAutoLayout(imagePlaceholder, firstLine, secondLine)
        layoutImagePlaceholder()
        layoutLines()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func layoutImagePlaceholder() {
        NSLayoutConstraint.activate([
            imagePlaceholder.topAnchor.constraint(equalTo: contentView.topAnchor),
            imagePlaceholder.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            imagePlaceholder.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            imagePlaceholder.heightAnchor.constraint(
                equalTo: imagePlaceholder.widthAnchor,
                multiplier: NewsCardCell.imageAspectRatio
            ),
        ])
    }

    private func layoutLines() {
        let bottom = secondLine.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -Spacing.m)
        bottom.priority = .required - 1

        NSLayoutConstraint.activate([
            firstLine.topAnchor.constraint(equalTo: imagePlaceholder.bottomAnchor, constant: Spacing.m),
            firstLine.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: Spacing.m),
            firstLine.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Spacing.m),
            firstLine.heightAnchor.constraint(equalToConstant: Self.lineHeight),
            secondLine.topAnchor.constraint(equalTo: firstLine.bottomAnchor, constant: Spacing.xs),
            secondLine.leadingAnchor.constraint(equalTo: firstLine.leadingAnchor),
            secondLine.widthAnchor.constraint(equalTo: contentView.widthAnchor, multiplier: 0.6),
            secondLine.heightAnchor.constraint(equalToConstant: Self.lineHeight),
            bottom,
        ])
    }
}

private extension ShimmerView {
    static func line() -> ShimmerView {
        let view = ShimmerView()
        view.layer.cornerRadius = 4
        view.layer.cornerCurve = .continuous
        return view
    }
}
