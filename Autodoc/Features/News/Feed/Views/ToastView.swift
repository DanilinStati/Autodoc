import UIKit

final class ToastView: UIView {
    private let iconView = UIImageView(image: UIImage(systemName: "exclamationmark.circle.fill"))
    private let label = UILabel()
    private lazy var stack = UIStackView(arrangedSubviews: [iconView, label])

    init(message: String) {
        super.init(frame: .zero)
        configureBackground()
        configureIcon()
        configureLabel(with: message)
        configureStack()
        layoutStack()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    static func show(_ message: String, in container: UIView, duration: TimeInterval = 3) {
        removeExisting(from: container)

        let toast = ToastView(message: message)
        toast.attach(to: container)
        UIAccessibility.post(notification: .announcement, argument: message)
        toast.animateAppearance(visibleFor: duration)
    }

    private static func removeExisting(from container: UIView) {
        container.subviews
            .compactMap { $0 as? ToastView }
            .forEach { $0.removeFromSuperview() }
    }

    private func attach(to container: UIView) {
        container.addSubviewsForAutoLayout(self)

        NSLayoutConstraint.activate([
            centerXAnchor.constraint(equalTo: container.centerXAnchor),
            bottomAnchor.constraint(equalTo: container.safeAreaLayoutGuide.bottomAnchor, constant: -Spacing.m),
            leadingAnchor.constraint(greaterThanOrEqualTo: container.layoutMarginsGuide.leadingAnchor),
            trailingAnchor.constraint(lessThanOrEqualTo: container.layoutMarginsGuide.trailingAnchor),
        ])
    }

    private func animateAppearance(visibleFor duration: TimeInterval) {
        alpha = 0
        transform = UIAccessibility.isReduceMotionEnabled ? .identity : CGAffineTransform(translationX: 0, y: 16)

        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.85, initialSpringVelocity: 0) {
            self.alpha = 1
            self.transform = .identity
        } completion: { _ in
            self.animateDisappearance(after: duration)
        }
    }

    private func animateDisappearance(after delay: TimeInterval) {
        UIView.animate(withDuration: 0.25, delay: delay, options: [.curveEaseIn]) {
            self.alpha = 0
        } completion: { _ in
            self.removeFromSuperview()
        }
    }

    private func configureBackground() {
        backgroundColor = UIColor.label.withAlphaComponent(0.92)
        layer.cornerRadius = 14
        layer.cornerCurve = .continuous
    }

    private func configureIcon() {
        iconView.tintColor = .systemBackground
        iconView.setContentHuggingPriority(.required, for: .horizontal)
        iconView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(textStyle: .subheadline)
    }

    private func configureLabel(with message: String) {
        label.text = message
        label.font = .preferred(.subheadline, weight: .medium)
        label.adjustsFontForContentSizeCategory = true
        label.textColor = .systemBackground
        label.numberOfLines = 0
    }

    private func configureStack() {
        stack.spacing = Spacing.xs
        stack.alignment = .center
    }

    private func layoutStack() {
        addSubviewsForAutoLayout(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: Spacing.s),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Spacing.s),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Spacing.m),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Spacing.m),
        ])
    }
}
