import Combine
import UIKit

final class NewsFeedViewController: UIViewController {
    private typealias DataSource = UICollectionViewDiffableDataSource<NewsFeedSection, NewsFeedItem>

    private let viewModel: NewsFeedViewModel
    private let imageLoader: ImageLoader
    private let refreshControl = UIRefreshControl()
    private var cancellables = Set<AnyCancellable>()
    private var currentState = NewsFeedViewModel.State()
    private var lastColumnCount = 0

    private lazy var collectionView = UICollectionView(
        frame: .zero,
        collectionViewLayout: NewsFeedLayout.make { [weak self] index in
            self?.sectionKind(at: index)
        }
    )
    private lazy var dataSource = makeDataSource()

    init(viewModel: NewsFeedViewModel, imageLoader: ImageLoader) {
        self.viewModel = viewModel
        self.imageLoader = imageLoader
        super.init(nibName: nil, bundle: nil)
        configureNavigationItem()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .feedBackground
        configureCollectionView()
        layoutCollectionView()
        configureRefreshControl()
        bindViewModel()
        viewModel.start()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.prefersLargeTitles = true
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        reconfigureCardsIfColumnCountChanged()
    }

    override func updateContentUnavailableConfiguration(using state: UIContentUnavailableConfigurationState) {
        switch currentState.content {
        case .failed(let message):
            contentUnavailableConfiguration = UIContentUnavailableConfiguration.feedLoadingFailed(message: message) { [weak self] in
                self?.viewModel.retry()
            }
        case .empty:
            contentUnavailableConfiguration = UIContentUnavailableConfiguration.feedEmpty()
        case .loading, .loaded:
            contentUnavailableConfiguration = nil
        }
    }

    // MARK: - Setup

    private func configureNavigationItem() {
        title = String(localized: "Новости")
        navigationItem.backButtonTitle = String(localized: "Новости")
        navigationItem.largeTitleDisplayMode = .always
    }

    private func configureCollectionView() {
        collectionView.backgroundColor = .clear
        collectionView.delegate = self
        collectionView.prefetchDataSource = self
        collectionView.allowsFocus = false
    }

    private func layoutCollectionView() {
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    private func configureRefreshControl() {
        refreshControl.addAction(UIAction { [weak self] _ in
            self?.viewModel.refresh()
        }, for: .valueChanged)
    }

    private func bindViewModel() {
        viewModel.$state
            .removeDuplicates()
            .sink { [weak self] state in
                self?.render(state)
            }
            .store(in: &cancellables)

        viewModel.notices
            .sink { [weak self] message in
                self?.showNotice(message)
            }
            .store(in: &cancellables)
    }

    // MARK: - Rendering

    private func render(_ state: NewsFeedViewModel.State) {
        let previous = currentState
        currentState = state

        updateRefreshControl(for: state)
        applySnapshot(for: state, animated: shouldAnimateChanges(from: previous, to: state))
        setNeedsUpdateContentUnavailableConfiguration()
    }

    private func updateRefreshControl(for state: NewsFeedViewModel.State) {
        let canRefresh = state.content == .loaded

        if canRefresh, collectionView.refreshControl == nil {
            collectionView.refreshControl = refreshControl
        } else if !canRefresh, collectionView.refreshControl != nil, !refreshControl.isRefreshing {
            collectionView.refreshControl = nil
        }

        if !state.isRefreshing, refreshControl.isRefreshing {
            refreshControl.endRefreshing()
        }
    }

    private func shouldAnimateChanges(from previous: NewsFeedViewModel.State, to state: NewsFeedViewModel.State) -> Bool {
        previous.content == .loaded && state.content == .loaded && view.window != nil
    }

    private func applySnapshot(for state: NewsFeedViewModel.State, animated: Bool) {
        dataSource.apply(NewsFeedSnapshotBuilder.snapshot(for: state), animatingDifferences: animated)
    }

    private func showNotice(_ message: String) {
        ToastView.show(message, in: view)
    }

    private func reconfigureCardsIfColumnCountChanged() {
        let columns = NewsFeedLayout.columnCount(forContentWidth: collectionView.bounds.width)

        guard columns != lastColumnCount else {
            return
        }

        let isInitialLayout = lastColumnCount == 0
        lastColumnCount = columns

        guard !isInitialLayout else {
            return
        }

        reconfigureArticles()
    }

    private func reconfigureArticles() {
        var snapshot = dataSource.snapshot()
        let articles = snapshot.itemIdentifiers.filter(\.isArticle)

        guard !articles.isEmpty else {
            return
        }

        snapshot.reconfigureItems(articles)
        dataSource.apply(snapshot, animatingDifferences: false)
    }

    private func sectionKind(at index: Int) -> NewsFeedLayout.SectionKind? {
        guard let section = dataSource.sectionIdentifier(for: index) else {
            return nil
        }

        switch section {
        case .grid:
            return .grid
        case .footer:
            return .footer
        }
    }

    // MARK: - Data source

    private func makeDataSource() -> DataSource {
        let cardRegistration = makeCardRegistration()
        let placeholderRegistration = UICollectionView.CellRegistration<NewsCardSkeletonCell, NewsFeedItem> { _, _, _ in }
        let footerRegistration = makeFooterRegistration()

        return DataSource(collectionView: collectionView) { collectionView, indexPath, item -> UICollectionViewCell? in
            switch item {
            case .article(let news):
                return collectionView.dequeueConfiguredReusableCell(using: cardRegistration, for: indexPath, item: news)
            case .placeholder:
                return collectionView.dequeueConfiguredReusableCell(using: placeholderRegistration, for: indexPath, item: item)
            case .footer(let pagination):
                return collectionView.dequeueConfiguredReusableCell(using: footerRegistration, for: indexPath, item: pagination)
            }
        }
    }

    private func makeCardRegistration() -> UICollectionView.CellRegistration<NewsCardCell, NewsItem> {
        UICollectionView.CellRegistration { [weak self] cell, _, item in
            guard let self else {
                return
            }

            cell.configure(with: item, imagePixelSize: self.cardImagePixelSize, imageLoader: self.imageLoader)
            cell.setReservesTitleSpace(self.isMultiColumn)
        }
    }

    private func makeFooterRegistration() -> UICollectionView.CellRegistration<PaginationFooterCell, NewsFeedViewModel.State.Pagination> {
        UICollectionView.CellRegistration { [weak self] cell, _, pagination in
            cell.configure(with: pagination) {
                self?.viewModel.retryNextPage()
            }
        }
    }

    // MARK: - Helpers

    private var isMultiColumn: Bool {
        NewsFeedLayout.columnCount(forContentWidth: collectionView.bounds.width) > 1
    }

    private var cardImagePixelSize: CGFloat {
        NewsFeedLayout.cardWidth(forContentWidth: collectionView.bounds.width) * displayScale
    }

    private var displayScale: CGFloat {
        traitCollection.displayScale > 0 ? traitCollection.displayScale : 3
    }

    private func articleIndex(of item: NewsFeedItem, at indexPath: IndexPath) -> Int? {
        switch item {
        case .article:
            indexPath.item
        default:
            nil
        }
    }

    private func share(_ item: NewsItem, from sourceView: UIView) {
        guard let url = item.articleURL else {
            return
        }

        let activity = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        activity.popoverPresentationController?.sourceItem = sourceView
        present(activity, animated: true)
    }

    private func makeShareMenu(for item: NewsItem, at indexPath: IndexPath) -> UIMenu {
        let share = UIAction(
            title: String(localized: "Поделиться"),
            image: UIImage(systemName: "square.and.arrow.up")
        ) { [weak self] _ in
            guard let self, let cell = self.collectionView.cellForItem(at: indexPath) else {
                return
            }

            self.share(item, from: cell)
        }

        return UIMenu(children: [share])
    }

    private func prefetchImage(for item: NewsFeedItem, maxPixelSize: CGFloat) {
        guard case .article(let news) = item, let url = news.imageURL else {
            return
        }

        imageLoader.prefetch(url, maxPixelSize: maxPixelSize)
    }
}

// MARK: - UICollectionViewDelegate

extension NewsFeedViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        dataSource.itemIdentifier(for: indexPath)?.newsItem != nil
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: false)

        guard let item = dataSource.itemIdentifier(for: indexPath)?.newsItem else {
            return
        }

        viewModel.select(item)
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard let item = dataSource.itemIdentifier(for: indexPath),
              let index = articleIndex(of: item, at: indexPath)
        else {
            return
        }

        viewModel.itemWillAppear(at: index)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        contextMenuConfigurationForItemsAt indexPaths: [IndexPath],
        point: CGPoint
    ) -> UIContextMenuConfiguration? {
        guard indexPaths.count == 1,
              let indexPath = indexPaths.first,
              let item = dataSource.itemIdentifier(for: indexPath)?.newsItem,
              item.articleURL != nil
        else {
            return nil
        }

        return UIContextMenuConfiguration(actionProvider: { [weak self] _ in
            self?.makeShareMenu(for: item, at: indexPath)
        })
    }
}

// MARK: - UICollectionViewDataSourcePrefetching

extension NewsFeedViewController: UICollectionViewDataSourcePrefetching {
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        let cardSize = cardImagePixelSize

        for indexPath in indexPaths {
            guard let item = dataSource.itemIdentifier(for: indexPath) else {
                continue
            }

            prefetchImage(for: item, maxPixelSize: cardSize)
        }
    }
}
