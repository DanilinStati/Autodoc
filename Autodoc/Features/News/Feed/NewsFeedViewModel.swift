import Combine
import Foundation

@MainActor
final class NewsFeedViewModel {
    nonisolated struct State: Equatable, Sendable {
        nonisolated enum Content: Hashable, Sendable {
            case loading
            case loaded
            case empty
            case failed(message: String)
        }

        nonisolated enum Pagination: Hashable, Sendable {
            case idle
            case loading
            case failed(message: String)
            case exhausted
        }

        var items: [NewsItem] = []
        var content: Content = .loading
        var pagination: Pagination = .idle
        var isRefreshing = false
    }

    @Published private(set) var state = State()

    var selection: AnyPublisher<NewsItem, Never> {
        selectionSubject.eraseToAnyPublisher()
    }

    var notices: AnyPublisher<String, Never> {
        noticesSubject.eraseToAnyPublisher()
    }

    private let repository: NewsRepository
    private let pageSize: Int
    private let prefetchDistance: Int
    private let selectionSubject = PassthroughSubject<NewsItem, Never>()
    private let noticesSubject = PassthroughSubject<String, Never>()

    private var nextPage = 1
    private var loadedIDs = Set<NewsItem.ID>()
    private var loadTask: Task<Void, Never>?
    private var hasStarted = false

    init(repository: NewsRepository, pageSize: Int = 15, prefetchDistance: Int = 6) {
        self.repository = repository
        self.pageSize = pageSize
        self.prefetchDistance = prefetchDistance
    }

    // MARK: - Inputs

    func start() {
        guard !hasStarted else {
            return
        }

        hasStarted = true
        load(page: 1, replacingContent: true)
    }

    func refresh() {
        guard state.content != .loading else {
            return
        }

        state.isRefreshing = true

        if state.pagination == .loading {
            state.pagination = .idle
        }

        load(page: 1, replacingContent: true)
    }

    func retry() {
        state.content = .loading
        load(page: 1, replacingContent: true)
    }

    func retryNextPage() {
        state.pagination = .idle
        loadNextPage()
    }

    func itemWillAppear(at index: Int) {
        guard index >= state.items.count - prefetchDistance else {
            return
        }

        loadNextPage()
    }

    func select(_ item: NewsItem) {
        selectionSubject.send(item)
    }

    // MARK: - Loading

    private var canLoadNextPage: Bool {
        state.content == .loaded && state.pagination == .idle && !state.isRefreshing
    }

    private func loadNextPage() {
        guard canLoadNextPage else {
            return
        }

        state.pagination = .loading
        load(page: nextPage, replacingContent: false)
    }

    private func load(page: Int, replacingContent: Bool) {
        loadTask?.cancel()
        loadTask = Task { [weak self, repository, pageSize] in
            do {
                let result = try await repository.fetchNews(page: page, pageSize: pageSize)

                guard !Task.isCancelled else {
                    return
                }

                self?.apply(result, page: page, replacingContent: replacingContent)
            } catch is CancellationError {
                return
            } catch {
                guard !Task.isCancelled else {
                    return
                }

                self?.handle(error, replacingContent: replacingContent)
            }
        }
    }

    private func apply(_ result: NewsPage, page: Int, replacingContent: Bool) {
        var newState = state

        if replacingContent {
            newState.items = []
            loadedIDs = []
        }

        newState.items.append(contentsOf: uniqueItems(from: result.items))
        newState.pagination = isLastPage(page, of: result) ? .exhausted : .idle
        newState.content = newState.items.isEmpty ? .empty : .loaded
        newState.isRefreshing = false

        nextPage = page + 1
        state = newState
    }

    private func uniqueItems(from items: [NewsItem]) -> [NewsItem] {
        items.filter { loadedIDs.insert($0.id).inserted }
    }

    private func isLastPage(_ page: Int, of result: NewsPage) -> Bool {
        result.items.isEmpty || page * pageSize >= result.totalCount
    }

    private func handle(_ error: Error, replacingContent: Bool) {
        let message = Self.message(for: error)
        var newState = state
        newState.isRefreshing = false

        if !replacingContent {
            newState.pagination = .failed(message: message)
        } else if newState.items.isEmpty {
            newState.content = .failed(message: message)
        } else {
            noticesSubject.send(message)
        }

        state = newState
    }

    static func message(for error: Error) -> String {
        switch error as? NetworkError {
        case .offline?:
            String(localized: "Нет подключения к интернету")
        case .timedOut?:
            String(localized: "Сервер долго не отвечает")
        case .httpStatus(let code)? where code >= 500:
            String(localized: "Сервер временно недоступен")
        case .decoding?:
            String(localized: "Не удалось прочитать ответ сервера")
        default:
            String(localized: "Не удалось загрузить новости")
        }
    }
}
