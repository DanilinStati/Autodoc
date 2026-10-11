import UIKit

final class ShimmerView: UIView {

    private static let animationKey = "shimmer"
    private static let animationDuration: CFTimeInterval = 1.4

    private let highlight = CAGradientLayer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureAppearance()
        configureHighlight()
        observeAppearanceChanges()
        observeReduceMotion()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        highlight.frame = bounds
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        restartAnimation()
    }

    private func configureAppearance() {
        backgroundColor = .skeleton
        clipsToBounds = true
    }

    private func configureHighlight() {
        highlight.startPoint = CGPoint(x: 0, y: 0.5)
        highlight.endPoint = CGPoint(x: 1, y: 0.5)
        highlight.locations = [-1, -0.5, 0]
        layer.addSublayer(highlight)
        updateHighlightColors()
    }

    private func observeAppearanceChanges() {
        registerForTraitChanges([UITraitUserInterfaceStyle.self]) { (view: ShimmerView, _) in
            view.updateHighlightColors()
        }
    }

    private func observeReduceMotion() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(restartAnimation),
            name: UIAccessibility.reduceMotionStatusDidChangeNotification,
            object: nil
        )
    }

    @objc
    private func restartAnimation() {
        highlight.removeAnimation(forKey: Self.animationKey)

        guard window != nil, !UIAccessibility.isReduceMotionEnabled else {
            return
        }

        highlight.add(makeSweepAnimation(), forKey: Self.animationKey)
    }

    private func makeSweepAnimation() -> CABasicAnimation {
        let now = highlight.convertTime(CACurrentMediaTime(), from: nil)
        let animation = CABasicAnimation(keyPath: "locations")
        animation.fromValue = [-1, -0.5, 0]
        animation.toValue = [1, 1.5, 2]
        animation.duration = Self.animationDuration
        animation.repeatCount = .infinity
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animation.beginTime = now - now.truncatingRemainder(dividingBy: Self.animationDuration)
        return animation
    }

    private func updateHighlightColors() {
        let alpha: CGFloat = traitCollection.userInterfaceStyle == .dark ? 0.06 : 0.45
        let shine = UIColor.white.withAlphaComponent(alpha)
        highlight.colors = [UIColor.clear.cgColor, shine.cgColor, UIColor.clear.cgColor]
    }
}
