import UIKit

enum NewsFeedSnapshotBuilder {
    typealias Snapshot = NSDiffableDataSourceSnapshot<NewsFeedSection, NewsFeedItem>

    private static let placeholderCount = 8

    static func snapshot(for state: NewsFeedViewModel.State) -> Snapshot {
        var snapshot = Snapshot()

        switch state.content {
        case .loading:
            appendPlaceholders(to: &snapshot)
        case .loaded:
            appendArticles(state.items, to: &snapshot)
            appendFooter(for: state.pagination, to: &snapshot)
        case .empty, .failed:
            break
        }

        return snapshot
    }

    private static func appendPlaceholders(to snapshot: inout Snapshot) {
        snapshot.appendSections([.grid])
        snapshot.appendItems((0..<placeholderCount).map(NewsFeedItem.placeholder), toSection: .grid)
    }

    private static func appendArticles(_ items: [NewsItem], to snapshot: inout Snapshot) {
        guard !items.isEmpty else {
            return
        }

        snapshot.appendSections([.grid])
        snapshot.appendItems(items.map(NewsFeedItem.article), toSection: .grid)
    }

    private static func appendFooter(for pagination: NewsFeedViewModel.State.Pagination, to snapshot: inout Snapshot) {
        guard pagination != .idle, !snapshot.sectionIdentifiers.isEmpty else {
            return
        }

        snapshot.appendSections([.footer])
        snapshot.appendItems([.footer(pagination)], toSection: .footer)
    }
}
