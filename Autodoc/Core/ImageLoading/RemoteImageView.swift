import UIKit

final class RemoteImageView: UIImageView {

    private let placeholderView = UIImageView(image: UIImage(systemName: "photo"))
    private var loadTask: Task<Void, Never>?
    private var representedURL: URL?
    private var pendingLoad: (url: URL, loader: ImageLoader)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureAppearance()
        configurePlaceholder()
        layoutPlaceholder()
    }

    convenience init() {
        self.init(frame: .zero)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        startPendingLoadIfSized()
    }

    func setImage(_ url: URL?, loader: ImageLoader) {
        guard let url, bounds.width == 0 else {
            pendingLoad = nil
            setImage(url, maxPixelSize: boundsPixelSize, loader: loader)
            return
        }

        cancel()
        image = nil
        showPlaceholder(false)
        pendingLoad = (url, loader)
    }

    func setImage(_ url: URL?, maxPixelSize: CGFloat, loader: ImageLoader) {
        guard !isAlreadyShowing(url) else {
            return
        }

        cancel()
        representedURL = url
        image = nil

        guard let url else {
            showPlaceholder(true)
            return
        }

        showPlaceholder(false)

        if let cached = loader.cachedImage(for: url, maxPixelSize: maxPixelSize) {
            image = cached
        } else {
            startLoading(url, maxPixelSize: maxPixelSize, loader: loader)
        }
    }

    func cancel() {
        loadTask?.cancel()
        loadTask = nil
        representedURL = nil
        pendingLoad = nil
    }

    // MARK: - Private

    private var boundsPixelSize: CGFloat {
        let scale = traitCollection.displayScale > 0 ? traitCollection.displayScale : 3
        return max(bounds.width, bounds.height) * scale
    }

    private func startPendingLoadIfSized() {
        guard let pendingLoad, bounds.width > 0 else {
            return
        }

        self.pendingLoad = nil
        setImage(pendingLoad.url, maxPixelSize: boundsPixelSize, loader: pendingLoad.loader)
    }

    private func isAlreadyShowing(_ url: URL?) -> Bool {
        guard let url, url == representedURL else {
            return false
        }

        return image != nil || loadTask != nil
    }

    private func startLoading(_ url: URL, maxPixelSize: CGFloat, loader: ImageLoader) {
        loadTask = Task { [weak self] in
            let loaded = try? await loader.image(for: url, maxPixelSize: maxPixelSize)

            guard let self, !Task.isCancelled, self.representedURL == url else {
                return
            }

            self.finishLoading(with: loaded)
        }
    }

    private func finishLoading(with loaded: UIImage?) {
        loadTask = nil

        if let loaded {
            reveal(loaded)
        } else {
            showPlaceholder(true)
        }
    }

    private func configureAppearance() {
        contentMode = .scaleAspectFill
        clipsToBounds = true
        backgroundColor = .skeleton
        accessibilityIgnoresInvertColors = true
    }

    private func configurePlaceholder() {
        placeholderView.tintColor = .tertiaryLabel
        placeholderView.contentMode = .scaleAspectFit
        placeholderView.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 32, weight: .regular)
        placeholderView.isHidden = true
        placeholderView.isAccessibilityElement = false
    }

    private func layoutPlaceholder() {
        placeholderView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(placeholderView)

        NSLayoutConstraint.activate([
            placeholderView.centerXAnchor.constraint(equalTo: centerXAnchor),
            placeholderView.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    private func showPlaceholder(_ visible: Bool) {
        placeholderView.isHidden = !visible
        backgroundColor = visible ? .secondarySystemFill : .skeleton
    }

    private func reveal(_ newImage: UIImage) {
        guard window != nil, !UIAccessibility.isReduceMotionEnabled else {
            image = newImage
            return
        }

        UIView.transition(with: self, duration: 0.25, options: [.transitionCrossDissolve, .allowUserInteraction]) {
            self.image = newImage
        }
    }
}
