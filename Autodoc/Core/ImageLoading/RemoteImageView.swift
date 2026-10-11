import UIKit

final class RemoteImageView: UIImageView {

    private struct Request {
        let url: URL
        let loader: ImageLoader
        var pixelSize: CGFloat = 0
    }

    private static let resizeTolerance: CGFloat = 1

    private let placeholderView = UIImageView(image: UIImage(systemName: "photo"))
    private var loadTask: Task<Void, Never>?
    private var request: Request?

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
        loadIfNeeded()
    }

    func setImage(_ url: URL?, loader: ImageLoader) {
        guard url == nil || url != request?.url else {
            return
        }

        cancel()
        image = nil

        guard let url else {
            showPlaceholder(true)
            return
        }

        showPlaceholder(false)
        request = Request(url: url, loader: loader)
        loadIfNeeded()
    }

    func cancel() {
        loadTask?.cancel()
        loadTask = nil
        request = nil
    }

    // MARK: - Private

    private var boundsPixelSize: CGFloat {
        let scale = traitCollection.displayScale > 0 ? traitCollection.displayScale : 3
        return max(bounds.width, bounds.height) * scale
    }

    private func loadIfNeeded() {
        guard let request, bounds.width > 0 else {
            return
        }

        let pixelSize = boundsPixelSize

        guard pixelSize > request.pixelSize + Self.resizeTolerance else {
            return
        }

        self.request?.pixelSize = pixelSize

        if let cached = request.loader.cachedImage(for: request.url, maxPixelSize: pixelSize) {
            loadTask?.cancel()
            loadTask = nil
            image = cached
        } else {
            startLoading(request.url, maxPixelSize: pixelSize, loader: request.loader)
        }
    }

    private func startLoading(_ url: URL, maxPixelSize: CGFloat, loader: ImageLoader) {
        loadTask?.cancel()
        loadTask = Task { [weak self] in
            let loaded = try? await loader.image(for: url, maxPixelSize: maxPixelSize)

            guard let self, !Task.isCancelled, self.request?.url == url else {
                return
            }

            self.finishLoading(with: loaded)
        }
    }

    private func finishLoading(with loaded: UIImage?) {
        loadTask = nil

        if let loaded {
            reveal(loaded)
        } else if image == nil {
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
